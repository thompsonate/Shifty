//
//  Setup.swift
//  
//
//  Created by Nate Thompson on 12/28/17.
//

import Cocoa
import AXSwift
import SwiftLog

class SetupWindowController: NSWindowController {
    override var storyboard: NSStoryboard {
        return NSStoryboard(name: "Setup", bundle: nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
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








class AccessibilityViewController: NSViewController {
    var observer: NSObjectProtocol!
    
    @IBOutlet weak var accessibilitySetupView: NSView!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        observer = DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if UIElement.isProcessTrusted() {
                    self.showNextView()
                }
            })
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        DistributedNotificationCenter.default().removeObserver(observer, name: NSNotification.Name("com.apple.accessibility.api"), object: nil)
    }
    
    func showNextView() {
        performSegue(withIdentifier: "showCompleteView", sender: self)
    }
}







class FinalViewController: NSViewController {
    @IBOutlet weak var analyticsPermissionButton: NSButton!
    
    @IBAction func analyticsDetailClicked(_ sender: Any) {
        presentAsSheet(AnalyticsDetailViewController())
    }
    
    override func viewWillDisappear() {
        PrefManager.shared.userDefaults.set(analyticsPermissionButton.state == .on,
                                            forKey: Keys.fabricCrashlyticsPermission)
    }
}








class ContainerViewController: NSViewController {
    var sourceViewController: NSViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let setupStoryboard = NSStoryboard(name: "Setup", bundle: nil)
        sourceViewController = setupStoryboard.instantiateController(withIdentifier: "sourceViewController") as? NSViewController
        self.insertChild(sourceViewController, at: 0)
        self.view.addSubview(sourceViewController.view)
        self.view.frame = sourceViewController.view.frame
        
        self.view.topAnchor.constraint(equalTo: sourceViewController.view.topAnchor).isActive = true
    }
}


