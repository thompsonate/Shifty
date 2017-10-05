//
//  AboutWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/26/17.
//
//

import Cocoa
import Sparkle

let ShiftyUpdater = SUUpdater()

class AboutWindow: NSWindowController {
    
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var iconCreditLabel: NSTextField!
    @IBOutlet weak var checkForUpdatesButton: NSButton!

    var statusMenuController: StatusMenuController!
    
    override var windowNibName: NSNib.Name {
        return NSNib.Name("AboutWindow")
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
        ShiftyUpdater.checkForUpdates(sender)
        Event.checkForUpdatesClicked.record()
    }
    
    @IBAction func visitWebsiteClicked(_ sender: NSButton) {
        if let url = URL(string: "http://shifty.natethompson.io"), NSWorkspace.shared.open(url) {
        }
        Event.websiteButtonClicked.record()
    }
    
    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        if let url = URL(string: "mailto:feedback@natethompson.io?subject=Shifty%20Feedback"), NSWorkspace.shared.open(url) {
        }
        Event.feedbackButtonClicked.record()
    }
    
    @IBAction func donateButtonClicked(_ sender: NSButton) {
        if let url = URL(string: "http://shifty.natethompson.io/donate"), NSWorkspace.shared.open(url) {
        }
        Event.donateButtonClicked.record()
    }
}
