//
//  PreferencesWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

struct Keys {
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
}

class PreferencesWindow: NSWindowController {
    
    @IBOutlet weak var toggleStatusItem: NSButton!
    let prefs = UserDefaults.standard
    var setStatusToggle: ((Void) -> Void)?
    
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
    
    @IBAction func toggleStatusItem(_ sender: Any) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        if toggleStatusItem.state == NSOnState {
            prefs.setValue(true, forKey: Keys.isStatusToggleEnabled)
            appDelegate.setStatusToggle()
        } else if toggleStatusItem.state == NSOffState {
            prefs.setValue(false, forKey: Keys.isStatusToggleEnabled)
            appDelegate.setStatusToggle()
        } else {
            print("oh no")
        }
    }
}
