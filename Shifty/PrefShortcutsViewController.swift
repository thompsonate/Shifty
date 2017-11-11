//
//  PrefShortcutsViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences

@objcMembers
class PrefShortcutsViewController: NSViewController, MASPreferencesViewController {
    
    override var nibName: NSNib.Name {
        get { return NSNib.Name("PrefShortcutsViewController") }
    }
    
    var viewIdentifier: String = "PrefShortcutsViewController"
    
    var toolbarItemImage: NSImage? {
        get { return NSImage(named: .computer)! }
    }
    
    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return "Shortcuts"
        }
    }
    
    var hasResizableWidth = false
    var hasResizableHeight = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
