//
//  BrowserRule.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 25/11/2017.
//

import ScriptingBridge
import AXSwift
import PublicSuffix

enum SupportedBrowser : String {
    case Safari = "com.apple.Safari"
    case SafariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    
    case Chrome = "com.google.Chrome"
    case ChromeCanary = "com.google.Chrome.canary"
    case Chromium = "org.chromium.Chromium"
}

var browserObserver: Observer!

//MARK: Safari Scripting Bridge

func getSafariCurrentTabURL(_ processIdentifier: pid_t) -> URL? {
    if let app: SafariApplication = SBApplication(processIdentifier: processIdentifier) {
        if let windows = app.windows as? [SafariWindow] {
            if !windows.isEmpty {
                if let tab = windows[0].currentTab {
                    if let url = URL(string: tab.URL!) {
                        return url
                    }
                }
            }
        }
    }
    return nil
}

@objc public protocol SafariApplication {
    @objc optional var windows: SBElementArray { get }
}
extension SBApplication: SafariApplication {}

@objc public protocol SafariWindow {
    @objc optional var currentTab: SafariTab { get } // The current tab.
}
extension SBObject: SafariWindow {}

@objc public protocol SafariTab {
    @objc optional var URL: String { get } // The current URL of the tab.
}
extension SBObject: SafariTab {}

//MARK: Chrome Scripting Bridge

func getChromeCurrentTabURL(_ processIdentifier: pid_t) -> URL? {
    if let app: ChromeApplication = SBApplication(processIdentifier: processIdentifier) {
        if let windows = app.windows as? [ChromeWindow] {
            if !windows.isEmpty {
                if let tab = windows[0].activeTab {
                    if let url = URL(string: tab.URL!) {
                        return url
                    }
                }
            }
        }
    }
    return nil
}

@objc public protocol ChromeApplication {
    @objc optional var windows: SBElementArray { get }
}
extension SBApplication: ChromeApplication {}

@objc public protocol ChromeWindow {
    @objc optional var activeTab: ChromeTab { get } // The current tab.
}
extension SBObject: ChromeWindow {}

@objc public protocol ChromeTab {
    @objc optional var URL: String { get } // The current URL of the tab.
}
extension SBObject: ChromeTab {}

private func isSubdomainOfDomain(subdomain: String, domain: String) -> Bool {
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

enum RuleType : String, Codable {
    case Domain
    case Subdomain
}

struct BrowserRule: CustomStringConvertible, Equatable, Codable {
    var type: RuleType
    var host: String
    var enableNightShift: Bool
    
    var description: String {
        return "Rule type; \(type) for host: \(host) enables NightSift: \(enableNightShift)"
    }
    static func ==(lhs: BrowserRule, rhs: BrowserRule) -> Bool {
        return lhs.type == rhs.type
            && lhs.host == rhs.host
            && lhs.enableNightShift == rhs.enableNightShift
    }
}

func getBrowserCurrentTabDomainSubdomain(browser: SupportedBrowser, processIdentifier: pid_t) -> (String, String) {
    var currentURL: URL? = nil
    var domain: String = ""
    var subdomain: String = ""
    
    switch browser {
    case .Safari, .SafariTechnologyPreview:
        if let url = getSafariCurrentTabURL(processIdentifier) {
            currentURL = url
        }
    case .Chrome, .ChromeCanary, .Chromium:
        if let url = getChromeCurrentTabURL(processIdentifier) {
            currentURL = url
        }
    }
    
    if let url = currentURL {
        domain = url.registeredDomain ?? ""
        subdomain = url.host ?? ""
    }
    return (domain, subdomain)
}

func subdomainRulesForDomain(domain: String, rules: [BrowserRule]) -> [BrowserRule] {
    return rules.filter {
        ($0.type == .Subdomain) && isSubdomainOfDomain(subdomain: $0.host, domain: domain)
    }
}

func checkDomainSubdomainForRules(domain: String, subdomain: String, rules: [BrowserRule]) -> (Bool, Bool, Bool) {
    var matchedDomain: Bool = false
    var matchedSubdomain: Bool = false
    var isException: Bool = false

    for rule in rules {
        switch rule.type {
        case .Domain:
            if rule.host == domain {
                matchedDomain = true
            }
        case .Subdomain:
            if rule.host == subdomain {
                matchedSubdomain = true
                isException = rule.enableNightShift
            }
        }
    }
    
    return (matchedDomain, matchedSubdomain, isException)
}

func startBrowserWatcher(_ processIdentifier: pid_t, callback: @escaping () -> Void) throws {
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

func stopBrowserWatcher() {
    if browserObserver != nil {
        browserObserver.stop()
        browserObserver = nil
    }
}



