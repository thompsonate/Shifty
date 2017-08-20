//
//  AppDelegate.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import ServiceManagement
import Fabric
import Crashlytics

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let prefs = UserDefaults.standard
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var statusItemClicked: ((Void) -> Void)?

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        Event.appLaunched.record()
                
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 4)) {
            Event.oldMacOSVersion(version: ProcessInfo().operatingSystemVersionString).record()
            let alert: NSAlert = NSAlert()
            alert.messageText = "This version of macOS does not support Night Shift"
            alert.informativeText = "Update your Mac to version 10.12.4 or higher to use Shifty."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            NSApplication.shared().terminate(self)
        }
        
        if !CBBlueLightClient.supportsBlueLightReduction() {
            Event.unsupportedHardware.record()
            let alert: NSAlert = NSAlert()
            alert.messageText = "Your Mac hardware does not support Night Shift"
            alert.informativeText = "A newer Mac is required to use Shifty."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            NSApplication.shared().terminate(self)
        }
        
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        
        var startedAtLogin = false
        for app in NSWorkspace.shared().runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
            }
        }
        
        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: Notification.Name("killme"), object: Bundle.main.bundleIdentifier!)
        }
        
        
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        setStatusToggle()
    }
    
    func setStatusToggle() {
        if prefs.bool(forKey: Keys.isStatusToggleEnabled) {
            statusItem.menu = nil
            if let button = statusItem.button {
                button.action = #selector(self.statusBarButtonClicked(sender:))
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
        } else {
            statusItem.menu = statusMenu
        }
    }
    
    func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEventType.rightMouseUp || event.modifierFlags.contains(.control)  {
            statusItem.menu = statusMenu
            statusItem.popUpMenu(statusMenu)
            statusItem.menu = nil
        } else {
            statusItemClicked?()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

