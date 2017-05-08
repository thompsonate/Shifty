//
//  PreferencesWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

class PreferencesWindow: NSWindowController {
    
    @IBOutlet weak var presetsTableView: NSTableView!
    
        override var windowNibName: String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.styleMask.remove(.resizable)
        self.window?.level = Int(CGWindowLevelForKey(.floatingWindow))
        NSApp.activate(ignoringOtherApps: true)

    }
    
}
