//
//  BrowserManager.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 25/11/2017.
//

import ScriptingBridge
import AXSwift
import PublicSuffix
import SwiftLog

var browserObserver: Observer!

typealias BundleIdentifier = String
enum SupportedBrowser: BundleIdentifier {
    typealias RawValue = String
    
    case safari = "com.apple.Safari"
    case safariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    
    case chrome = "com.google.Chrome"
    case chromeCanary = "com.google.Chrome.canary"
    case chromium = "org.chromium.Chromium"
    case vivaldi = "com.vivaldi.Vivaldi"
    
    init?(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    init?(_ application: NSRunningApplication) {
        if let bundleIdentifier = application.bundleIdentifier {
            self.init(bundleIdentifier)
        } else {
            return nil
        }
    }
}


enum BrowserManager {
    static var currentURL: URL? {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return nil
        }
        
        guard let application = RuleManager.currentApp,
            let browser = SupportedBrowser(application),
            let app: Browser = SBApplication(application) else {
                return nil
        }
        return urlFor(browser, app)
    }
    
    static var currentDomain: String? {
        return currentURL?.registeredDomain
    }
    
    static var currentSubdomain: String? {
        return currentURL?.host
    }
    
    static var currrentAppIsSupportedBrowser: Bool {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return false
        }
        
        guard let currentApp = RuleManager.currentApp else { return false }
        return SupportedBrowser(currentApp) != nil
    }
    
    static var hasValidDomain: Bool {
        return currentDomain != nil
    }
    
    static var hasValidSubdomain: Bool {
        if let currentDomain = currentDomain {
            if currentDomain == currentSubdomain || currentSubdomain == "www.\(currentDomain)" {
                return false
            }
        }
        return currentSubdomain != nil
    }
    
    
    static func updateForSupportedBrowser() {
        guard let pid = NSWorkspace.shared.menuBarOwningApplication?.processIdentifier else { return }
        
        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            do {
                try startBrowserWatcher(pid) {
                    if RuleManager.ruleForSubdomain == .enabled {
                        NightShiftManager.respond(to: .nightShiftEnableRuleActivated)
                    } else if RuleManager.disabledForDomain || RuleManager.ruleForSubdomain == .disabled {
                        NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
                    } else {
                        NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
                    }
                }
            } catch let error {
                NSLog("Error: Could not watch app [\(pid)]: \(error)")
                logw("Error: Could not watch app [\(pid)]: \(error)")
            }
            if RuleManager.ruleForSubdomain == .enabled {
                NightShiftManager.respond(to: .nightShiftEnableRuleActivated)
            } else if RuleManager.disabledForDomain || RuleManager.ruleForSubdomain == .disabled {
                NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
            } else {
                NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
            }
        }
    }
    
    private static func startBrowserWatcher(_ processIdentifier: pid_t, callback: @escaping () -> Void) throws {
        if let app = Application(forProcessID: processIdentifier) {
            browserObserver = app.createObserver { (observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in
                if event == .windowCreated {
                    do {
                        try browserObserver.addNotification(.titleChanged, forElement: element)
                    } catch let error {
                        NSLog("Error: Could not watch [\(element)]: \(error)")
                    }
                }
                if event == .titleChanged || event == .focusedWindowChanged {
                    DispatchQueue.main.async {
                        callback()
                    }
                }
            }
            
            do {
                let windows = try app.windows()!
                for window in windows {
                    do {
                        try browserObserver.addNotification(.titleChanged, forElement: window)
                    } catch let error {
                        NSLog("Error: Could not watch [\(window)]: \(error)")
                    }
                }
            } catch let error {
                NSLog("Error: Could not get windows for \(app): \(error)")
            }
            try browserObserver.addNotification(.focusedWindowChanged, forElement: app)
            try browserObserver.addNotification(.windowCreated, forElement: app)
        }
    }
    
    static func stopBrowserWatcher() {
        if browserObserver != nil {
            browserObserver.stop()
            browserObserver = nil
        }
    }
    
    private static func browserSwitchedURL(observer: AXObserver, element: AXUIElement, notification: CFString, userInfo: UnsafeMutableRawPointer?) {
        switch notification as String {
        case kAXWindowCreatedNotification:
            registerWindow(element, forNotificationsUsing: observer, userInfo: userInfo)
        case kAXTitleChangedNotification,
             kAXFocusedWindowChangedNotification:
            guard let userInfo = userInfo,
                let application = Optional.some(Unmanaged<NSRunningApplication>.fromOpaque(userInfo).takeUnretainedValue()),
                let browser = SupportedBrowser(application),
                let app: Browser = SBApplication(application) else {
                    assertionFailure("Could not extract browser")
                    return
            }
            let _ = urlFor(browser, app)
        default:
            assertionFailure("Invalid AXNotification")
            return
        }
    }
    
    private static func urlFor(_ browser: SupportedBrowser, _ application: Browser) -> URL? {
        guard let window = (application.windows as? [Window])?.first else {
            assertionFailure("Could not extract browser window")
            return nil
        }
        let tab: Tab?
        switch browser {
        case .safari, .safariTechnologyPreview:
            tab = window.currentTab
        case .chrome, .chromeCanary, .chromium, .vivaldi:
            tab = window.activeTab
        }
        return tab?.URL.flatMap(URL.init(string:))
    }
    
    private static func registerWindow(_ window: AXUIElement, forNotificationsUsing observer: AXObserver, userInfo: UnsafeMutableRawPointer?) {
        AXObserverAddNotification(observer, window, kAXWindowCreatedNotification as CFString, userInfo)
        AXObserverAddNotification(observer, window, kAXTitleChangedNotification as CFString, userInfo)
        AXObserverAddNotification(observer, window, kAXFocusedWindowChangedNotification as CFString, userInfo)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
    
    private static func isSubdomainOfDomain(subdomain: String, domain: String) -> Bool {
        var subdomainComponents = subdomain.components(separatedBy: ".")
        var domainComponents = domain.components(separatedBy: ".")
        let subdomainComponentsCount = subdomainComponents.count
        let domainComponentsCount = domainComponents.count
        let offset = subdomainComponentsCount - domainComponentsCount
        if offset < 0 {
            return false
        }
        for i in offset..<subdomainComponentsCount {
            if !(subdomainComponents[i] == domainComponents[i - offset]) {
                return false
            }
        }
        return true
    }
}
