//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import Sparkle
import MASPreferences_Shifty

let ShiftyUpdater = SUUpdater()

@objcMembers
class PrefAboutViewController: NSViewController, MASPreferencesViewController {
    
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefAboutViewController") }
    }
    
    var viewIdentifier: String = "PrefAboutViewController"
    
    var toolbarItemImage: NSImage? {
        get { return #imageLiteral(resourceName: "shiftyColorIcon") }
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
        guard let url = URL(string: "http://shifty.natethompson.io") else { return }
        NSWorkspace.shared.open(url)
        Event.websiteButtonClicked.record()
    }
    
    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        guard let url = URL(string: "mailto:feedback@natethompson.io?subject=Shifty%20Feedback") else { return }
        NSWorkspace.shared.open(url)
        Event.feedbackButtonClicked.record()
    }
    
    @IBAction func donateButtonClicked(_ sender: NSButton) {
        guard let url = URL(string: "http://shifty.natethompson.io/donate") else { return }
        NSWorkspace.shared.open(url)
        Event.donateButtonClicked.record()
    }
    
    @IBAction func creditsButtonClicked(_ sender: Any) {
        guard let path = Bundle.main.path(forResource: "credits", ofType: "rtf") else { return }
        NSWorkspace.shared.openFile(path)
    }
}


class LinkButton: NSButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func resetCursorRects() {
        addCursorRect(self.bounds, cursor: .pointingHand)
    }
}

