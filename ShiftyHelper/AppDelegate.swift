//
//  AppDelegate.swift
//  ShiftyHelper
//
//  Created by Nate Thompson on 7/15/17.
//
//

import Cocoa

class ShiftyHelperApplication: NSApplication {
    let strongDelegate = AppDelegate()
    
    override init() {
        super.init()
        self.delegate = strongDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let mainAppIdentifier = "io.natethompson.Shifty"
        let running = NSWorkspace.shared.runningApplications
        var alreadyRunning = false
        
        for app in running {
            if app.bundleIdentifier == mainAppIdentifier {
                alreadyRunning = true
                break
            }
        }
        
        if !alreadyRunning {
			DistributedNotificationCenter.default().addObserver(NSApp as Any,
                                                                selector: #selector(NSApplication.terminate(_:)),
                                                                name: Notification.Name("terminateApp"),
                                                                object: mainAppIdentifier)
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Shifty")
            
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(newPath)
        } else {
            NSApp.terminate(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("helper app terminated")
        // Insert code here to tear down your application
    }


}

