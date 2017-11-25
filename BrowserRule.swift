//
//  BrowserRule.swift
//  Shifty
//
//  Created by Enrico Ghirardi on 25/11/2017.
//

import ScriptingBridge
import AXSwift

enum SupportedBrowser : String {
    case Safari                  = "com.apple.Safari"
    case SafariTechnologyPreview = "com.apple.SafariTechnologyPreview"
    case Chrome                  = "com.google.Chrome"
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

extension URL {
    func matchesDomain(domain: String, includeSubdomains: Bool) -> Bool {
        if let self_host = self.host {
            if includeSubdomains {
                var selfHostComponents = self_host.components(separatedBy: ".")
                var targetHostComponents = domain.components(separatedBy: ".")
                let selfComponentsCount = selfHostComponents.count
                let targetComponentsCount = targetHostComponents.count
                let offset = selfComponentsCount - targetComponentsCount
                if offset < 0 {
                    return false
                }
                for i in offset..<selfComponentsCount {
                    if !(selfHostComponents[i] == targetHostComponents[i - offset]) {
                        return false
                    }
                }
                return true
            } else {
                return self_host == domain
            }
        }
        return false
    }
}

var disabledHosts = [
    "netflix.com"
]

func checkBroserForRule(browser: SupportedBrowser, processIdentifier: pid_t) -> Bool {
    switch browser {
    case .Safari, .SafariTechnologyPreview:
        if let url = getSafariCurrentTabURL(processIdentifier) {
            for host in disabledHosts {
                if url.matchesDomain(domain: host, includeSubdomains: true) {
                    return true
                }
            }
        }
    case .Chrome:
        if let url = getChromeCurrentTabURL(processIdentifier) {
            for host in disabledHosts {
                if url.matchesDomain(domain: host, includeSubdomains: true) {
                    return true
                }
            }
        }
    }
    
    return false
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



