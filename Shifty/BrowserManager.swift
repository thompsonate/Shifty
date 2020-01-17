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


typealias BundleIdentifier = String

enum SupportedBrowserID: BundleIdentifier {
    case safari = "com.apple.Safari"
    case safariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    
    case chrome = "com.google.Chrome"
    case chromeCanary = "com.google.Chrome.canary"
    case chromium = "org.chromium.Chromium"
    
    case edge = "com.microsoft.edgemac"
    case edgeBeta = "com.microsoft.edgemac.Beta"
    
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


enum BrowserManager {
    private static var browserObserver: Observer?
    private static var observedApp: Application?
    private static var focusedWindow: UIElement?
    
    private static var cachedBrowsers: [SupportedBrowserID: BrowserProtocol] = [:]
    
    
    static var currentURL: URL? {
        if !UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            return nil
        }
        guard let application = RuleManager.currentApp,
            let browserID = SupportedBrowserID(application) else {
                return nil
        }
        
        if let cachedBrowser = cachedBrowsers[browserID] {
            return url(for: cachedBrowser, withBundleID: browserID)
            
        } else if let browser = SBApplication(bundleIdentifier: browserID.rawValue) {
            cachedBrowsers[browserID] = browser
            return url(for: browser, withBundleID: browserID)
        } else {
            return nil
        }
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
        return SupportedBrowserID(currentApp) != nil
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
    private static func tryStartBrowserWatcher(
        repeatCount: Int,
        processIdentifier: pid_t,
        callback: @escaping () -> Void)
    {
        let maxTries = 10
        
        do {
            try startBrowserWatcher(processIdentifier, callback: callback)
        } catch let error {
            if repeatCount < maxTries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tryStartBrowserWatcher(
                        repeatCount: repeatCount + 1,
                        processIdentifier: processIdentifier,
                        callback: callback)
                }
            } else {
                logw("Error: Could not watch app [\(processIdentifier)]: \(error)")
            }
        }
    }
    
    
    
    private static func startBrowserWatcher(
        _ processIdentifier: pid_t,
        callback: @escaping () -> Void) throws
    {
        guard let observedApp = Application(forProcessID: processIdentifier) else { return }
        
        browserObserver = observedApp.createObserver { (
            observer: Observer,
            element: UIElement,
            event: AXNotification,
            info: [String: AnyObject]?) in
            
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
                } catch {
                    logw("Error: Unable to obtain focused window: \(error)")
                }
                DispatchQueue.main.async {
                    callback()
                }
            default:
                logw("Error: Unexpected notification \(event) received")
            }
        }
        try browserObserver?.addNotification(.valueChanged, forElement: observedApp)
        try browserObserver?.addNotification(.focusedWindowChanged, forElement: observedApp)
        try browserObserver?.addNotification(.uiElementDestroyed, forElement: observedApp)
        focusedWindow = try observedApp.attribute(.focusedWindow)
    }
    
    
    
    static func stopBrowserWatcher() {
        guard let browserObserver = browserObserver else { return }
        
        if let observedApp = observedApp {
            do {
                try browserObserver.removeNotification(.valueChanged, forElement: observedApp)
                try browserObserver.removeNotification(.focusedWindowChanged, forElement: observedApp)
                try browserObserver.removeNotification(.uiElementDestroyed, forElement: observedApp)
            } catch let error {
                logw("Error: Couldn't remove notifications: \(error)")
            }
            BrowserManager.observedApp = nil
        }
        focusedWindow = nil
        browserObserver.stop()
        BrowserManager.browserObserver = nil
    }
    
    
    
    enum BrowserError: Error {
        case closedApp
        case noWindow
        case axError
        case notFullScreen
    }
    
    
    
    private static func url(for browser: BrowserProtocol, withBundleID browserID: SupportedBrowserID) -> URL? {
        if !browser.isRunning {
            logw("Error: Could not get url, app already closed")
            return nil
        }
        guard let windows = browser.windows?(), let window = windows.firstObject as? Window else {
            logw("Error: Could not get url, there are no windows")
            return nil
        }
        
        let tab: Tab?
        switch browserID {
        case .chrome, .chromeCanary, .chromium, .edge, .edgeBeta, .opera, .operaBeta, .operaDeveloper, .vivaldi:
            tab = window.activeTab
        case .safari, .safariTechnologyPreview:
            do {
                // Try to get URL from special full screen window (i.e. full screen video)
                return try safariFullScreenURL(for: browser)
                
            } catch BrowserError.notFullScreen {
                tab = window.currentTab
                
            } catch BrowserError.axError {
                logw("Error: Could not get url using AX API")
                tab = window.currentTab
                
            } catch {
                logw("Error: Could not get url, \(error)")
                return nil
            }
        }
        return tab?.URL.flatMap(URL.init(string:))
    }
    
    
    
    private static func safariFullScreenURL(for browser: BrowserProtocol) throws -> URL? {
        guard let app = RuleManager.currentApp,
            let axapp = Application(app),
            let axwin: UIElement = try axapp.attribute(.focusedWindow),
            let axwin_children: [UIElement] = try axwin.arrayAttribute(.children)
            else { throw BrowserError.axError }
        
        if axwin_children.count == 1 {
            // Special fullscreen win
            var axchild = axwin_children[0]
            for _ in 1...3 {
                guard let children: [UIElement] = try axchild.arrayAttribute(.children) else { throw BrowserError.axError }
                if !children.isEmpty {
                    axchild = children[0]
                }
            }
            return try axchild.attribute("AXURL")
        } else {
            throw BrowserError.notFullScreen
        }
    }
}
