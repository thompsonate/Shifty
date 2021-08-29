//
//  RuleManager.swift
//
//
//  Created by Saagar Jha on 1/14/18.
//

import Cocoa
import SwiftLog
import ScriptingBridge


class RuleManager {
    static var shared = RuleManager()
    
    var disabledApps = Set<AppRule>() {
        didSet {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(disabledApps), forKey: Keys.disabledApps)
        }
    }
    
    
    
    var browserRules = Set<BrowserRule>() {
        didSet(newValue) {
            UserDefaults.standard.set(try? PropertyListEncoder().encode(browserRules), forKey: Keys.browserRules)
        }
    }
    
    
    
    var currentApp: NSRunningApplication? {
        return NSWorkspace.shared.menuBarOwningApplication
    }
    
    
    
    var disabledForApp: Bool {
        get {
            guard let bundleIdentifier = currentApp?.bundleIdentifier else {
                logw("Could not obtain bundle identifier of current application")
                return false
            }
            return disabledApps.filter {
                $0.bundleIdentifier == bundleIdentifier }.count > 0
        }
        set(newValue) {
            guard let bundleIdentifier = currentApp?.bundleIdentifier else {
                logw("Could not obtain bundle identifier of current application")
                return
            }
            let rule = AppRule(bundleIdentifier: bundleIdentifier, fullScreenOnly: false)
            if newValue {
                disabledApps.insert(rule)
                NightShiftManager.shared.respond(to: .nightShiftDisableRuleActivated)
            } else {
                guard let index = disabledApps.firstIndex(of: rule) else { return }
                disabledApps.remove(at: index)
                NightShiftManager.shared.respond(to: .nightShiftDisableRuleDeactivated)
            }
        }
    }
    
    
    
    var disabledForDomain: Bool {
        get {
            guard let currentDomain = BrowserManager.shared.currentDomain else { return false }
            let disabledDomain = browserRules.filter {
                $0.type == .domain && $0.host == currentDomain }.count > 0
            return disabledDomain
        }
        set(newValue) {
            guard let currentDomain = BrowserManager.shared.currentDomain else { return }
            let rule = BrowserRule(type: .domain, host: currentDomain)
            if newValue {
                browserRules.insert(rule)
                NightShiftManager.shared.respond(to: .nightShiftDisableRuleActivated)
            } else {
                guard let index = browserRules.firstIndex(of: rule) else { return }
                
                if ruleForSubdomain == .enabled {
                    ruleForSubdomain = .none
                }
                browserRules.remove(at: index)
                NightShiftManager.shared.respond(to: .nightShiftDisableRuleDeactivated)
            }
        }
    }
    
    
    
    var ruleForSubdomain: SubdomainRuleType {
        get {
            guard let currentSubdomain = BrowserManager.shared.currentSubdomain else { return .none }
            
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
            guard let currentSubdomain = BrowserManager.shared.currentSubdomain else { return }
            
            switch newValue {
            case .disabled:
                let rule = BrowserRule(type: .subdomainDisabled, host: currentSubdomain)
                browserRules.insert(rule)
                NightShiftManager.shared.respond(to: .nightShiftDisableRuleActivated)
            case .enabled:
                let rule = BrowserRule(type: .subdomainEnabled, host: currentSubdomain)
                browserRules.insert(rule)
                NightShiftManager.shared.respond(to: .nightShiftEnableRuleActivated)
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
                guard let index = browserRules.firstIndex(of: rule) else { return }
                browserRules.remove(at: index)
                
                switch prevValue {
                case .disabled:
                    NightShiftManager.shared.respond(to: .nightShiftDisableRuleDeactivated)
                case .enabled:
                    NightShiftManager.shared.respond(to: .nightShiftEnableRuleDeactivated)
                case .none:
                    break
                }
            }
        }
    }
    
    
    
    var disableRuleIsActive: Bool {
        return disabledForApp || (disabledForDomain && ruleForSubdomain != .enabled) || ruleForSubdomain == .disabled
    }
    
    
    
    func removeRulesForCurrentState() {
        disabledForApp = false
        disabledForDomain = false
        ruleForSubdomain = .none
    }
    
    

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil,
                                                          queue: nil) {
            self.appSwitched(notification: $0)
        }
        
        if let appData = UserDefaults.standard.value(forKey: Keys.disabledApps) as? Data {
            do {
                disabledApps = try PropertyListDecoder().decode(Set<AppRule>.self, from: appData)
            } catch let error {
                logw("Error: \(error.localizedDescription)")
            }
        }
        
        if let browserData = UserDefaults.standard.value(forKey: Keys.browserRules) as? Data {
            do {
                browserRules = try PropertyListDecoder().decode(Set<BrowserRule>.self, from: browserData)
            } catch let error {
                logw("Error: \(error.localizedDescription)")
            }
        }
    }
    
    

    private func appSwitched(notification: Notification) {
        BrowserManager.shared.stopBrowserWatcher()
        if disabledForApp {
            NightShiftManager.shared.respond(to: .nightShiftDisableRuleActivated)
        } else if BrowserManager.shared.currentAppIsSupportedBrowser {
            BrowserManager.shared.updateForSupportedBrowser()
        } else {
            NightShiftManager.shared.respond(to: .nightShiftDisableRuleDeactivated)
        }
    }

    
}



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



struct AppRule: CustomStringConvertible, Hashable, Codable {
    var bundleIdentifier: BundleIdentifier
    var fullScreenOnly: Bool
    
    var description: String {
        return "Rule for \(bundleIdentifier); full screen only: \(fullScreenOnly)"
    }
    
    static func == (lhs: AppRule, rhs: AppRule) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
            && lhs.fullScreenOnly == rhs.fullScreenOnly
    }
}



struct BrowserRule: CustomStringConvertible, Hashable, Codable {
    var type: RuleType
    var host: String

    var description: String {
        return "Rule type: \(type) for host: \(host)"
    }

    static func == (lhs: BrowserRule, rhs: BrowserRule) -> Bool {
        return lhs.type == rhs.type
            && lhs.host == rhs.host
    }
}
