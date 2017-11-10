//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences

@objcMembers
class PrefGeneralViewController: NSViewController, MASPreferencesViewController {
    
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefGeneralViewController") }
    }
    
    var viewIdentifier: String = "PrefGeneralViewController"
    
    var toolbarItemImage: NSImage? {
        get { return NSImage(named: .preferencesGeneral)! }
    }
    
    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return "General"
        }
    }
    
    var hasResizableWidth = false
    var hasResizableHeight = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    
}
