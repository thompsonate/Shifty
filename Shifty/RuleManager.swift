//
//  RuleManager.swift
//
//
//  Created by Saagar Jha on 1/14/18.
//

import Cocoa
import SwiftLog
import ScriptingBridge

typealias BundleIdentifier = String
enum SupportedBrowser: BundleIdentifier {
    case safari = "com.apple.Safari"
    case safariTechnologyPreview = "com.apple.SafariTechnologyPreview"

    case chrome = "com.google.Chrome"
    case chromeCanary = "com.google.Chrome.canary"
    case chromium = "org.chromium.Chromium"

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

enum RuleType: String, Codable {
    case domain
    case subdomain
}

struct BrowserRule: CustomStringConvertible, Hashable, Codable {
    var type: RuleType
    var host: String
    var enableNightShift: Bool

    var description: String {
        return "Rule type; \(type) for host: \(host) enables NightSift: \(enableNightShift)"
    }

    var hashValue: Int {
        return type.hashValue ^ host.hashValue ^ enableNightShift.hashValue
    }

    static func == (lhs: BrowserRule, rhs: BrowserRule) -> Bool {
        return lhs.type == rhs.type
            && lhs.host == rhs.host
            && lhs.enableNightShift == rhs.enableNightShift
    }
}

enum RuleManager {
    static var disabledApps = Set<BundleIdentifier>() {
        didSet {

        }
    }
    
    static var currentApp: NSRunningApplication? {
        return NSWorkspace.shared.menuBarOwningApplication
    }
    
    static var disabledForApp: Bool {
        get {
            guard let bundleIdentifier = currentApp?.bundleIdentifier else {
                logw("Could not obtain bundle identifier of current application")
                return false
            }
            return disabledApps.contains(bundleIdentifier)
        }
        set(newValue) {
            guard let bundleIdentifier = currentApp?.bundleIdentifier else {
                logw("Could not obtain bundle identifier of current application")
                return
            }
            if newValue {
                disabledApps.insert(bundleIdentifier)
            } else {
                disabledApps.remove(bundleIdentifier)
            }
        }
    }
    
    static var browserRules = Set<BrowserRule>() {
        didSet {

        }
    }

    static var currentURL: URL? {
        guard let application = currentApp,
            let browser = SupportedBrowser(application),
            let app: Browser = SBApplication(application) else {
                return nil
        }
        return urlFor(browser, app)
    }
    
    static var disabledForDomain: Bool {
        get {
            return false
        }
        set(newValue) {
            if newValue {
                
            } else {
                
            }
        }
    }
    
    static var disabledForSubdomain: Bool {
        get {
            return false
        }
        set(newValue) {
            if newValue {
                
            } else {
                
            }
        }
    }
    
    static var disableRuleIsActive: Bool {
        return disabledForApp || disabledForDomain || disabledForSubdomain
    }
    
    static func removeRulesForCurrentState() {
        disabledForApp = false
        disabledForDomain = false
        disabledForSubdomain = false
    }

    public static func initialize() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) {
            RuleManager.appSwitched(notification: $0)
        }

        disabledApps = PrefManager.shared.userDefaults.value(forKey: Keys.disabledApps) as? Set<String> ?? []
        guard let data = PrefManager.shared.userDefaults.value(forKey: Keys.browserRules) as? Data else {
            return
        }
        do {
            browserRules = try PropertyListDecoder().decode(Set<BrowserRule>.self, from: data)
        } catch let error {
            NSLog("Error: \(error.localizedDescription)")
        }
    }

    private static func appSwitched(notification: Notification) {
        guard let application = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication),
            let bundleIdentier = application.bundleIdentifier,
            let processIdentifier = Optional.some(application.processIdentifier) else {
                return
        }
        if disabledApps.contains(bundleIdentier) {
            NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
        } else if SupportedBrowser(application) != nil {
            var observer = AXObserver?.none
            AXObserverCreate(processIdentifier, {
                RuleManager.browserSwitchedURL(observer: $0, element: $1, notification: $2, userInfo: $3)
            }, &observer)
            var windows = CFTypeRef?.none
            AXUIElementCopyAttributeValue(AXUIElementCreateApplication(processIdentifier), "AXWindows" as CFString, &windows)
            for window in windows as? [AXUIElement] ?? [] {
                _ = observer.flatMap {
                    let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(application).toOpaque())
                    registerWindow(window, forNotificationsUsing: $0, userInfo: userInfo)
                }
            }
        } else {
            NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
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
        case .chrome, .chromeCanary, .chromium:
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
}
