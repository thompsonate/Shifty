//
//  StatusMenuController.swift
//  Night-Shift-Tool
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    @IBAction func nsOn(_ sender: NSMenuItem) {
//        float strength = 0.75;
//        CBBlueLightClient *client = [[CBBlueLightClient alloc] init];
//        if (strength != 0.0) { [client setStrength:strength commit:true]; }
//        [client setEnabled:(strength != 0.0)];
    }
    
    @IBAction func nsOff(_ sender: NSMenuItem) {
//        float strength = 0.0;
//        CBBlueLightClient *client = [[CBBlueLightClient alloc] init];
//        if (strength != 0.0) { [client setStrength:strength commit:true]; }
//        [client setEnabled:(strength != 0.0)];

    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}

