//
//  RuleManager.swift
//
//
//  Created by Saagar Jha on 1/14/18.
//

import Cocoa
import SwiftLog
import ScriptingBridge


enum RuleType: String, Codable {
    case domain
    case subdomainDisabled
    case subdomainEnabled
}

enum SubdomainRuleType: String, Codable {
    case none
    case disabled
    case enabled
}

struct BrowserRule: CustomStringConvertible, Hashable, Codable {
    var type: RuleType
    var host: String

    var description: String {
        return "Rule type: \(type) for host: \(host)"
    }

    var hashValue: Int {
        return type.hashValue ^ host.hashValue
    }

    static func == (lhs: BrowserRule, rhs: BrowserRule) -> Bool {
        return lhs.type == rhs.type
            && lhs.host == rhs.host
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
                NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
            } else {
                disabledApps.remove(bundleIdentifier)
                NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
            }
        }
    }
    
    static var browserRules = Set<BrowserRule>() {
        didSet(newValue) {
        }
    }
    
    static var disabledForDomain: Bool {
        get {
            guard let currentDomain = BrowserManager.currentDomain else { return false }
            let disabledDomain = browserRules.filter {
                $0.type == .domain && $0.host == currentDomain }.count > 0
            return disabledDomain
        }
        set(newValue) {
            guard let currentDomain = BrowserManager.currentDomain else { return }
            let rule = BrowserRule(type: .domain, host: currentDomain)
            if newValue {
                browserRules.insert(rule)
                NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
            } else {
                guard let index = browserRules.index(of: rule) else { return }
                
                if ruleForSubdomain == .enabled {
                    ruleForSubdomain = .none
                }
                browserRules.remove(at: index)
                NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
            }
        }
    }
    
    static var ruleForSubdomain: SubdomainRuleType {
        get {
            guard let currentSubdomain = BrowserManager.currentSubdomain else { return .none }
            
            if disabledForDomain {
                let isEnabled = (browserRules.filter {
                    $0.type == .subdomainEnabled
                        && $0.host == currentSubdomain
                    }.count > 0)
                if isEnabled {
                    return .enabled
                }
            } else {
                let isDisabled = (browserRules.filter {
                    $0.type == .subdomainDisabled
                        && $0.host == currentSubdomain
                    }.count > 0)
                if isDisabled {
                    return .disabled
                }
            }
            return .none
        }
        set(newValue) {
            guard let currentSubdomain = BrowserManager.currentSubdomain else { return }
            
            switch newValue {
            case .disabled:
                let rule = BrowserRule(type: .subdomainDisabled, host: currentSubdomain)
                browserRules.insert(rule)
                NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
            case .enabled:
                let rule = BrowserRule(type: .subdomainEnabled, host: currentSubdomain)
                browserRules.insert(rule)
                NightShiftManager.respond(to: .nightShiftEnableRuleActivated)
            case .none:
                var rule: BrowserRule
                let prevValue = ruleForSubdomain
                
                //Remove rule from set before triggering NightShiftEvent
                switch prevValue {
                case .disabled:
                    rule = BrowserRule(type: .subdomainDisabled, host: currentSubdomain)
                case .enabled:
                    rule = BrowserRule(type: .subdomainEnabled, host: currentSubdomain)
                case .none:
                    return
                }
                guard let index = browserRules.index(of: rule) else { return }
                browserRules.remove(at: index)
                
                switch prevValue {
                case .disabled:
                    NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
                case .enabled:
                    NightShiftManager.respond(to: .nightShiftEnableRuleDeactivated)
                case .none:
                    break
                }
            }
        }
    }
    
    static var disableRuleIsActive: Bool {
        return disabledForApp || (disabledForDomain && ruleForSubdomain != .enabled) || ruleForSubdomain == .disabled
    }
    
    static func removeRulesForCurrentState() {
        disabledForApp = false
        disabledForDomain = false
        ruleForSubdomain = .none
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
            let bundleIdentier = application.bundleIdentifier else {
                return
        }
        if disabledApps.contains(bundleIdentier) {
            NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
        } else if BrowserManager.currrentAppIsSupportedBrowser {
            BrowserManager.updateForSupportedBrowser()
        } else {
            NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
        }
    }

    
}
