//
//  AboutWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/26/17.
//
//

import Cocoa

class AboutWindow: NSWindowController {
    
    @IBOutlet weak var versionLabel: NSTextField!
    
    override var windowNibName: String! {
        return "AboutWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.styleMask.remove(.resizable)
        NSApp.activate(ignoringOtherApps: true)
        
        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let version = versionObject as? String ?? ""
        versionLabel.stringValue = "Version \(version)"
    }
    
    override func keyDown(with theEvent: NSEvent) {
        if theEvent.keyCode == 13 {
            window?.close()
        }
    }
     
    @IBAction func checkUpdateClicked(_ sender: NSButton) {
        
        Event.checkForUpdatesClicked.record()
    }
    
    @IBAction func visitWebsiteClicked(_ sender: NSButton) {
        if let url = URL(string: "http://shifty.natethompson.io"), NSWorkspace.shared().open(url) {
        }
        Event.websiteButtonClicked.record()
    }
    
    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        if let url = URL(string: "mailto:feedback@natethompson.io?subject=Shifty%20Feedback"), NSWorkspace.shared().open(url) {
        }
        Event.feedbackButtonClicked.record()
    }
}
