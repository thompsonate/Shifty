//
//  BrowserRule.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 25/11/2017.
//

import ScriptingBridge
import AXSwift
import PublicSuffix

var browserObserver: Observer!

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

//func getBrowserCurrentTabDomainSubdomain(browser: SupportedBrowser, processIdentifier: pid_t) -> (String, String) {
//    var currentURL: URL? = nil
//    var domain: String = ""
//    var subdomain: String = ""
//
//    switch browser {
//    case .safari, .safariTechnologyPreview:
//        if let url = getSafariCurrentTabURL(processIdentifier) {
//            currentURL = url
//        }
//    case .chrome, .chromeCanary, .chromium:
//        if let url = getChromeCurrentTabURL(processIdentifier) {
//            currentURL = url
//        }
//    }
//
//    if let url = currentURL {
//        domain = url.registeredDomain ?? ""
//        subdomain = url.host ?? ""
//    }
//    return (domain, subdomain)
//}

func subdomainRulesForDomain(domain: String, rules: [BrowserRule]) -> [BrowserRule] {
    return rules.filter {
        ($0.type == .subdomain) && isSubdomainOfDomain(subdomain: $0.host, domain: domain)
    }
}

func checkForBrowserRules(domain: String, subdomain: String, rules: [BrowserRule]) -> (Bool, Bool, Bool) {
    let disabledDomain = rules.filter {
        $0.type == .domain && $0.host == domain }.count > 0
    var res: Bool
    var isException: Bool
    if disabledDomain {
        res = (rules.filter {
            $0.type == .subdomain
                && $0.host == subdomain
                && $0.enableNightShift == true
        }.count > 0)
        isException = res
    } else {
        res = (rules.filter {
            $0.type == .subdomain
                && $0.host == subdomain
                && $0.enableNightShift == false
        }.count > 0)
        isException = false
    }
    return (disabledDomain, res, isException)
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
