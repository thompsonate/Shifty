//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences

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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
