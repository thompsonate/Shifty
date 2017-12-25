//
//  AccessibilityPromptWindow.swift
//  
//
//  Created by Nate Thompson on 12/2/17.
//

import Cocoa
import SwiftLog

class AccessibilityPromptWindow: NSWindowController {
   
    @IBOutlet weak var openSysPrefsButton: NSButton!
    
    override var windowNibName: NSNib.Name {
        return NSNib.Name("AccessibilityPromptWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.styleMask.remove(.resizable)
        self.window?.level = .floating
        
        openSysPrefsButton.title = NSLocalizedString("alert.open_preferences", comment: "Open System Preferences")
    }
    
    @IBAction func openSysPrefsClicked(sender: AnyObject) {
        window?.close()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        logw("Open System Preferences button clicked")
    }
    
    @IBAction func notNowClicked(_ sender: Any) {
        window?.close()
        logw("Not now button clicked")
    }
}
