//
//  AccessibilityPromptWindow.swift
//  
//
//  Created by Nate Thompson on 12/2/17.
//

import Cocoa

class AccessibilityPromptWindow: NSWindowController {
    
    override var windowNibName: NSNib.Name {
        return NSNib.Name("AccessibilityPromptWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.styleMask.remove(.resizable)
        self.window?.level = .floating
    }
    
    @IBAction func openSysPrefsClicked(sender: AnyObject) {
        window?.close()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    @IBAction func notNowClicked(_ sender: Any) {
        window?.close()
    }
}
