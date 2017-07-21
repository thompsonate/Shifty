//
//  CustomTimeWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/21/17.
//
//

import Cocoa

class CustomTimeWindow: NSWindowController {
    
    var disableCustomTime: ((Int) -> Void)?
    
    override var windowNibName: String! {
        return "CustomTimeWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.styleMask.remove(.resizable)
        self.window?.level = Int(CGWindowLevelForKey(.floatingWindow))
        self.window?.standardWindowButton(NSWindowButton.closeButton)?.isHidden = true
        self.window?.standardWindowButton(NSWindowButton.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(NSWindowButton.zoomButton)?.isHidden = true
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBOutlet weak var hoursTextField: NSTextField!
    @IBOutlet weak var minutesTextField: NSTextField!
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        window?.close()
    }
    
    @IBAction func okButtonClicked(_ sender: NSButton) {
        let hours = hoursTextField.intValue
        let minutes = minutesTextField.intValue
        let timeIntervalInSeconds = hours * 3600 + minutes * 60
        print(timeIntervalInSeconds)
        disableCustomTime?(Int(timeIntervalInSeconds))
        window?.close()
    }
}
