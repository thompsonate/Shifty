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
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let lastKnownLocation = "lastKnownLocation"
    static let sunriseSetTimes = "sunriseSetTimes"
    static let disabledApps = "disabledApps"
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var setAutoLaunch: NSButton!
    @IBOutlet weak var toggleStatusItem: NSButton!
    @IBOutlet weak var darkModeSync: NSButton!
    
    let prefs = UserDefaults.standard
    var setStatusToggle: (() -> Void)?
    
    override var windowNibName: NSNib.Name {
        return NSNib.Name("PreferencesWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = self
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        if theEvent.keyCode == 13 {
            window?.close()
        } else if theEvent.keyCode == 46 {
            window?.miniaturize(Any?.self)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        Event.preferences(autoLaunch: setAutoLaunch.state == .on, quickToggle: toggleStatusItem.state == .on, syncDarkMode: darkModeSync.state == .on).record()
    }
    
    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let autoLaunch = setAutoLaunch.state == .on
        prefs.setValue(autoLaunch, forKey: Keys.isAutoLaunchEnabled)
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, autoLaunch)
    }
    
    @IBAction func toggleStatusItem(_ sender: NSButtonCell) {
        let quickToggle = toggleStatusItem.state == .on
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        prefs.setValue(quickToggle, forKey: Keys.isStatusToggleEnabled)
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
            Keys.isStatusToggleEnabled: NSNumber(value: false),
            Keys.disabledApps: [String]()
            ] as [String : Any]
        
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
