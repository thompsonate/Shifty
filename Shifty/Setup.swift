//
//  Setup.swift
//  
//
//  Created by Nate Thompson on 12/28/17.
//

import Cocoa
import SwiftLog

class SetupWindowController: NSWindowController {
    override var storyboard: NSStoryboard {
        return NSStoryboard(name: .init("Setup"), bundle: nil)
    }
}

class SetupWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            close()
        } else if event.keyCode == 46 && event.modifierFlags.contains(.command) {
            miniaturize(self)
        }
    }
}

class SetupView: NSView {
    @IBAction func accessibilityHelp(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185")!)
    }
    
    @IBAction func openSystemPrefsClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        logw("Open System Preferences button clicked")
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        window?.close()
    }
}

var isAccessibilityViewVisible = false

class AccessibilityViewController: NSViewController {
    static let shared = AccessibilityViewController()
    
    override func viewDidAppear() {
        super.viewDidAppear()
        isAccessibilityViewVisible = true
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        isAccessibilityViewVisible = false
    }
    
    func showNextView() {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("showNextView"), sender: self)
    }
}

class ContainerViewController: NSViewController {
    var sourceViewController: NSViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let setupStoryboard = NSStoryboard(name: .init("Setup"), bundle: nil)
        sourceViewController = setupStoryboard.instantiateController(withIdentifier: .init("sourceViewController")) as! NSViewController
        self.insertChildViewController(sourceViewController, at: 0)
        self.view.addSubview(sourceViewController.view)
        self.view.frame = sourceViewController.view.frame
        
        self.view.topAnchor.constraint(equalTo: sourceViewController.view.topAnchor).isActive = true
    }
}


