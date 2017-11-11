//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import Sparkle
import MASPreferences

let ShiftyUpdater = SUUpdater()

@objcMembers
class PrefAboutViewController: NSViewController, MASPreferencesViewController {
    
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefAboutViewController") }
    }
    
    var viewIdentifier: String = "PrefAboutViewController"
    
    var toolbarItemImage: NSImage? {
        get { return #imageLiteral(resourceName: "statusIcon") }
    }
    
    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return "About"
        }
    }
    
    var hasResizableWidth = false
    var hasResizableHeight = false
    
    @IBOutlet weak var versionLabel: NSTextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        versionLabel.stringValue = versionObject as? String ?? ""
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
