//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var preferencesWindow: PreferencesWindow!

    @IBOutlet weak var sliderView: SliderView!
    var sliderMenuItem: NSMenuItem!
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        preferencesWindow = PreferencesWindow()
        
        sliderMenuItem = statusMenu.item(withTitle: "Slider")
        sliderMenuItem.view = sliderView
    }
    
    @IBAction func nsOn(_ sender: NSMenuItem) {
        shift(strength: 0.75)
    }
    
    @IBAction func nsOff(_ sender: NSMenuItem) {
        shift(strength: 0.0)
    }
    
    func shift(strength: Float) {
        let client = CBBlueLightClient()
        if strength != 0.0 {client.setStrength(strength, commit: true)}
        client.setEnabled(strength != 0.0)
    }
    
    func shift(boolean: Bool) {
        let client = CBBlueLightClient()
        client.setEnabled(boolean)
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}

