//
//  PreferencesWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa
import ServiceManagement

struct Keys {
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
    static let isAutoLaunchEnabled = "isAutoLaunchEnabled"
}

class PreferencesWindow: NSWindowController {
    
    @IBOutlet weak var setAutoLaunch: NSButton!
    @IBOutlet weak var toggleStatusItem: NSButton!
    let prefs = UserDefaults.standard
    var setStatusToggle: ((Void) -> Void)?
    
    override var windowNibName: String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.styleMask.remove(.resizable)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        if theEvent.keyCode == 13 {
            window?.close()
        } else if theEvent.keyCode == 46 {
            window?.miniaturize(Any?.self)
        }
    }
    
    func readLoginItems() {
        let domain = prefs.persistentDomain(forName: "loginwindow")
        if let domain = domain {
            let value: Any? = domain["AutoLaunchedApplicationDictionary"]
            if let items = value as? Array<Any> {
                print(items)
            }
        }
    }
    
    @IBAction func setAutoLaunch(_ sender: Any) {
        readLoginItems()
        prefs.setValue(setAutoLaunch.state == NSOnState, forKey: Keys.isAutoLaunchEnabled)
    }
    
    func dialogOK(text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = NSAlertStyle.warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @IBAction func toggleStatusItem(_ sender: Any) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        prefs.setValue(toggleStatusItem.state == NSOnState, forKey: Keys.isStatusToggleEnabled)
        appDelegate.setStatusToggle()
    }
}

class PreferencesManager {
    static let sharedInstance = PreferencesManager()
    
    private init() {
        registerFactoryDefaults()
    }
    
    let userDefaults = UserDefaults.standard
    
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.isAutoLaunchEnabled: NSNumber(value: false),
            Keys.isStatusToggleEnabled: NSNumber(value: false)
            ]
        
        userDefaults.register(defaults: factoryDefaults)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
    
    func reset() {
        userDefaults.removeObject(forKey: Keys.isAutoLaunchEnabled)
        userDefaults.removeObject(forKey: Keys.isStatusToggleEnabled)
        synchronize()
    }
}
