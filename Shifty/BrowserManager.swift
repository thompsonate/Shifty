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
var observedApp: Application!
var focusedWindow: UIElement!

enum BrowserError: Error {
    case closedApp
    case noWindow
    case axError
}

typealias BundleIdentifier = String

enum SupportedBrowser: BundleIdentifier {
    case safari = "com.apple.Safari"
    case safariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    
    case chrome = "com.google.Chrome"
    case chromeCanary = "com.google.Chrome.canary"
    case chromium = "org.chromium.Chromium"
    
    case opera = "com.operasoftware.Opera"
    case operaBeta = "com.operasoftware.OperaNext"
    case operaDeveloper = "com.operasoftware.OperaDeveloper"
    
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

var cachedBrowsers: [SupportedBrowser: Browser] = [:]

enum BrowserManager {
    
    static var currentURL: URL? {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return nil
        }
        
        guard let application = RuleManager.currentApp,
            let browser = SupportedBrowser(application) else {
                return nil
        }
        if cachedBrowsers[browser] == nil {
            guard let bundleID: String = application.bundleIdentifier,
                  let app: Browser = SBApplication(bundleIdentifier: bundleID) else {
                return nil
            }
            cachedBrowsers[browser] = app
        }
        
        let app = cachedBrowsers[browser]!
        var url : URL? = nil
        
        do {
            url = try urlFor(browser, app, UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled))
        } catch BrowserError.axError {
            logw("Error: Could not get url using AX API")
            do {
                url = try urlFor(browser, app, false)
            } catch {
                logw("Error: backup methods failed")
            }
        } catch BrowserError.closedApp {
            logw("Error: Could not get url, app already closed")
        } catch BrowserError.noWindow {
            logw("Error: Could not get url, there are no windows")
        } catch {
            logw("Error: Could not get url, unknown error")
        }
        return url
    }
    
    
    
    static var currentDomain: String? {
        return currentURL?.registeredDomain
    }
    
    static var currentSubdomain: String? {
        return currentURL?.host
    }
    
    
    
    static var currentAppIsSupportedBrowser: Bool {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return false
        }
        
        guard let currentApp = RuleManager.currentApp else { return false }
        return SupportedBrowser(currentApp) != nil
    }
    
    
    
    /// Returns the AppleEvent Automation permission state of the current app.
    /// Blocks main thread if user is prompted for consent.
    /// I don't think this is currently an issue since the prompt will appear when the browser becomes the current app.
    static var permissionToAutomateCurrentApp: PrivacyConsentState {
        guard let bundleID = RuleManager.currentApp?.bundleIdentifier else { return .undetermined }

        return AppleEventsManager.automationConsent(forBundleIdentifier: bundleID)
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
        observedApp = Application(forProcessID: processIdentifier)
        if observedApp != nil {
            browserObserver = observedApp.createObserver { (observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in
                switch event {
                case .valueChanged, .uiElementDestroyed:
                    if element == focusedWindow {
                        fallthrough
                    }
                    if let role = try? element.role(), role == .staticText {
                        fallthrough
                    }
                case .focusedWindowChanged:
                    do {
                        focusedWindow  = try observedApp.attribute(.focusedWindow)
                    } catch let error {
                        logw("Error: Unable to obtain focused window: \(error)")
                    }
                    DispatchQueue.main.async {
                        callback()
                    }
                default:
                    logw("Error: Unexpected notification \(event) received")
                }
            }
            try browserObserver.addNotification(.valueChanged, forElement: observedApp)
            try browserObserver.addNotification(.focusedWindowChanged, forElement: observedApp)
            try browserObserver.addNotification(.uiElementDestroyed, forElement: observedApp)
            focusedWindow = try observedApp.attribute(.focusedWindow)
        }
    }
    
    
    
    static func stopBrowserWatcher() {
        if browserObserver != nil {
            if observedApp != nil {
                do {
                    try browserObserver.removeNotification(.valueChanged, forElement: observedApp)
                    try browserObserver.removeNotification(.focusedWindowChanged, forElement: observedApp)
                    try browserObserver.removeNotification(.uiElementDestroyed, forElement: observedApp)
                } catch let error {
                    logw("Error: Couldn't remove notifications: \(error)")
                }
                observedApp = nil
            }
            if focusedWindow != nil {
                focusedWindow = nil
            }
            browserObserver.stop()
            browserObserver = nil
        }
    }
    
    
    
    private static func urlFor(_ browser: SupportedBrowser, _ application: Browser, _ ax_api: Bool) throws -> URL? {
        if !application.isRunning {
            throw BrowserError.closedApp
        }
        guard let window = (application.windows?() as? [Window])?.first else {
            throw BrowserError.noWindow
        }
        let tab: Tab?
        switch browser {
        case .chrome, .chromeCanary, .chromium, .opera, .operaBeta, .operaDeveloper, .vivaldi:
            tab = window.activeTab
        case .safari, .safariTechnologyPreview:
            if ax_api {
                guard let app = RuleManager.currentApp else { throw BrowserError.axError }
                guard let axapp = Application(app) else { throw BrowserError.axError }
                guard let axwin: UIElement = try axapp.attribute(.focusedWindow) else { throw BrowserError.axError }
                guard let axwin_children: [UIElement] = try axwin.arrayAttribute(.children) else { throw BrowserError.axError }
                switch axwin_children.count {
                case 1:
                    // Special fullscreen win
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
            } else {
                tab = window.currentTab
            }
        }
        return tab?.URL.flatMap(URL.init(string:))
    }
}
