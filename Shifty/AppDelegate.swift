//
//  AppDelegate.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let prefs = UserDefaults.standard
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var statusItemClicked: ((Void) -> Void)?

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
        
        if event.type == NSEventType.rightMouseUp {
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

