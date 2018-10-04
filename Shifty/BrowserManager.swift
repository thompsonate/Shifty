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

enum BrowserError: Error {
    case noWindow
    case axError
}

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
        
        do {
            let url = try urlFor(browser, app)
            return url
        } catch {
            do {
                let url = try urlFor(browser, app)
                return url
            } catch {
                return nil
            }
        }
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
            tryStartBrowserWatcher(repeatCount: 0, processIdentifier: pid, callback: fireNightShiftEvent)
            fireNightShiftEvent()
        }
    }
    
    private static func fireNightShiftEvent() {
        if RuleManager.ruleForSubdomain == .enabled {
            NightShiftManager.respond(to: .nightShiftEnableRuleActivated)
        } else if RuleManager.disabledForDomain || RuleManager.ruleForSubdomain == .disabled {
            NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
        } else {
            NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
        }
    }
    
    // When browser is launching, we're not able to add a notification right away, so we need to try again.
    private static func tryStartBrowserWatcher(repeatCount: Int, processIdentifier: pid_t, callback: @escaping () -> Void) {
        let maxTries = 10
        
        do {
            try startBrowserWatcher(processIdentifier, callback: callback)
        } catch let error {
            if repeatCount < maxTries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tryStartBrowserWatcher(repeatCount: repeatCount + 1, processIdentifier: processIdentifier, callback: callback)
                }
            } else {
                logw("Error: Could not watch app [\(processIdentifier)]: \(error)")
            }
        }
    }
    
    private static func startBrowserWatcher(_ processIdentifier: pid_t, callback: @escaping () -> Void) throws {
        if let app = Application(forProcessID: processIdentifier) {
            browserObserver = app.createObserver { (observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in
                switch event {
                case .valueChanged:
                    if let role = try? element.role(), role == .staticText {
                        fallthrough
                    }
                case .focusedWindowChanged:
                    DispatchQueue.main.async {
                        callback()
                    }
                default:
                    logw("Error: Unexpected notification \(event) received")
                }
            }
            try browserObserver.addNotification(.valueChanged, forElement: app)
            try browserObserver.addNotification(.focusedWindowChanged, forElement: app)
        }
    }
    
    static func stopBrowserWatcher() {
        if browserObserver != nil {
            browserObserver.stop()
            browserObserver = nil
        }
    }
    
    private static func urlFor(_ browser: SupportedBrowser, _ application: Browser) throws -> URL? {
        guard let window = (application.windows as? [Window])?.first else {
            throw BrowserError.noWindow
        }
        let tab: Tab?
        switch browser {
        case .chrome, .chromeCanary, .chromium, .vivaldi:
            tab = window.activeTab
        case .safari, .safariTechnologyPreview:
            if let app = RuleManager.currentApp,
                let axapp = Application(app) {
                do {
                    // Special fullscreen win
                    guard let axwin: UIElement = try axapp.attribute(.focusedWindow) else { throw BrowserError.axError }
                    guard let axwin_children: [UIElement] = try axwin.arrayAttribute(.children) else { throw BrowserError.axError }
                    switch axwin_children.count {
                    case 1:
                        var axchild = axwin_children[0]
                        for _ in 1...3 {
                            guard let children: [UIElement] = try axchild.arrayAttribute(.children) else { throw BrowserError.axError }
                            if !children.isEmpty {
                                axchild = children[0]
                            }
                        }
                        return try axchild.attribute("AXURL")
                    case 2...7:
                        // Standard win
                        var filtered = try axwin_children.filter {
                            let role = try $0.role()
                            return role == .splitGroup
                        }
                        
                        if filtered.count == 1 {
                            let child_lvl1 = filtered[0]
                            guard let children_lvl1: [UIElement] =
                                try child_lvl1.arrayAttribute(.children) else { throw BrowserError.axError }
                            filtered = try children_lvl1.filter {
                                let role = try $0.role()
                                return role == .tabGroup
                            }
                            if filtered.count == 1 {
                                var axchild = filtered[0]
                                for _ in 1...3 {
                                    guard let children: [UIElement] = try axchild.arrayAttribute(.children) else { throw BrowserError.axError }
                                    if !children.isEmpty {
                                        axchild = children[0]
                                    }
                                }
                                guard let children_lvl2: [UIElement] =
                                    try axchild.arrayAttribute(.children) else { throw BrowserError.axError }
                                filtered = try children_lvl2.filter {
                                    let role = try $0.role()
                                    return role == Role.init(rawValue: "AXWebArea")
                                }
                                if filtered.count == 1 {
                                    return try filtered[0].attribute("AXURL")
                                }
                            }
                        }
                        fallthrough
                    default:
                        throw BrowserError.axError
                    }
                } catch {
                    tab = window.currentTab
                }
            } else {
                tab = window.currentTab
            }
        }
        return tab?.URL.flatMap(URL.init(string:))
    }
}
