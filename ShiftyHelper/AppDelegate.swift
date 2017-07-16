//
//  AppDelegate.swift
//  ShiftyHelper
//
//  Created by Nate Thompson on 7/15/17.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    public func applicationDidFinishLaunching(_ notification: Notification) {
        let mainAppIdentifier = "io.natethompson.Shifty"
        let running = NSWorkspace.shared().runningApplications
        var alreadyRunning = false
        
        for app in running {
            if app.bundleIdentifier == mainAppIdentifier {
                alreadyRunning = true
                break
            }
        }
        
        if !alreadyRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name:  Notification.Name("killme"), object: mainAppIdentifier)
            
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Shifty")
            
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared().launchApplication(newPath)
        } else {
            self.terminate()
        }
    }
    
    func terminate() {
        NSApp.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("helper app terminated")
        // Insert code here to tear down your application
    }


}

