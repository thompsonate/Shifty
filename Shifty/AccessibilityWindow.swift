//
//  AccessibilityWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 1/1/18.
//

import Cocoa

class AccessibilityWindow: NSWindowController {

    @IBOutlet weak var notNowButton: NSButton!
    @IBOutlet weak var openSysPrefsButton: NSButton!
    
    override var windowNibName: NSNib.Name {
        get { return "AccessibilityWindow" }
    }
    
    override func windowDidLoad() {
        window?.center()
        
        notNowButton.title = NSLocalizedString("alert.not_now", comment: "Not now")
        openSysPrefsButton.title = NSLocalizedString("alert.open_preferences", comment: "Open System Preferences")
    }
    
    @IBAction func openSysPrefsClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        window?.close()
        NSApp.stopModal()
    }
    
    @IBAction func notNowClicked(_ sender: Any) {
        window?.close()
        NSApp.stopModal()
    }
    
    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185")!)
        window?.close()
        NSApp.stopModal()
    }
}
