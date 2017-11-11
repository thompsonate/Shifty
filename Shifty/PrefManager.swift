//
//  PrefManager.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

struct Keys {
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
    static let isAutoLaunchEnabled = "isAutoLaunchEnabled"
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let lastKnownLocation = "lastKnownLocation"
    static let disabledApps = "disabledApps"
}

//class PreferencesWindow: NSWindowController, NSWindowDelegate {
//    
//    @IBOutlet weak var setAutoLaunch: NSButton!
//    @IBOutlet weak var toggleStatusItem: NSButton!
//    @IBOutlet weak var darkModeSync: NSButton!
//    
//    @IBOutlet weak var schedulePopup: NSPopUpButton!
//    @IBOutlet weak var offMenuItem: NSMenuItem!
//    @IBOutlet weak var customMenuItem: NSMenuItem!
//    @IBOutlet weak var sunMenuItem: NSMenuItem!
//    
//    @IBOutlet weak var fromTimePicker: NSDatePicker!
//    @IBOutlet weak var toTimePicker: NSDatePicker!
//    @IBOutlet weak var fromLabel: NSTextField!
//    @IBOutlet weak var toLabel: NSTextField!
//    
//    let prefs = UserDefaults.standard
//    var setStatusToggle: (() -> Void)?
//    var updateSchedule: (() -> Void)?
//    var updateDarkMode: (() -> Void)!
//    
//    override var windowNibName: NSNib.Name {
//        return NSNib.Name("PreferencesWindow")
//    }
//
//    override func windowDidLoad() {
//        super.windowDidLoad()
//        window?.delegate = self
//        
//        self.window?.center()
//        self.window?.makeKeyAndOrderFront(nil)
//        NSApp.activate(ignoringOtherApps: true)
//        
//        updateSchedule = {
//            switch BLClient.schedule {
//            case .off:
//                self.schedulePopup.select(self.offMenuItem)
//                self.showScheduleDates(displayed: false)
//            case .timedSchedule(startTime: let startTime, endTime: let endTime):
//                self.schedulePopup.select(self.customMenuItem)
//                self.fromTimePicker.dateValue = startTime
//                self.toTimePicker.dateValue = endTime
//                self.showScheduleDates(displayed: true)
//            case .sunSchedule:
//                self.schedulePopup.select(self.sunMenuItem)
//                self.showScheduleDates(displayed: false)
//            }
//        }
//        
//        updateSchedule?()
//    }
//    
//    override func keyDown(with theEvent: NSEvent) {
//        if theEvent.keyCode == 13 {
//            window?.close()
//        } else if theEvent.keyCode == 46 {
//            window?.miniaturize(Any?.self)
//        }
//    }
//    
//    func windowWillClose(_ notification: Notification) {
//        Event.preferences(autoLaunch: setAutoLaunch.state == .on,
//                          quickToggle: toggleStatusItem.state == .on,
//                          syncDarkMode: darkModeSync.state == .on,
//                          schedule: BLClient.schedule).record()
//    }
//    
//    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
//        let autoLaunch = setAutoLaunch.state == .on
//        prefs.setValue(autoLaunch, forKey: Keys.isAutoLaunchEnabled)
//        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
//        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, autoLaunch)
//    }
//    
//    @IBAction func quickToggle(_ sender: NSButtonCell) {
//        let quickToggle = toggleStatusItem.state == .on
//        let appDelegate = NSApplication.shared.delegate as! AppDelegate
//        prefs.setValue(quickToggle, forKey: Keys.isStatusToggleEnabled)
//        appDelegate.setStatusToggle()
//    }
//    
//    @IBAction func syncDarkMode(_ sender: NSButtonCell) {
//        updateDarkMode()
//        if !UserDefaults.standard.bool(forKey: Keys.isDarkModeSyncEnabled) {
//            SLSSetAppearanceThemeLegacy(false)
//        }
//    }
//    
//    @IBAction func schedulePopup(_ sender: Any) {
//        if schedulePopup.selectedItem == offMenuItem {
//            BLClient.setSchedule(.off)
//            showScheduleDates(displayed: false)
//        } else if schedulePopup.selectedItem == customMenuItem {
//            BLClient.setMode(2)
//            showScheduleDates(displayed: true)
//        } else if schedulePopup.selectedItem == sunMenuItem {
//            BLClient.setMode(1)
//            showScheduleDates(displayed: false)
//        }
//    }
//    
//    @IBAction func scheduleTimePickers(_ sender: Any) {
//        let fromTime = fromTimePicker.dateValue
//        let toTime = toTimePicker.dateValue
//        BLClient.setSchedule(.timedSchedule(startTime: fromTime, endTime: toTime))
//    }
//    
//    func showScheduleDates(displayed: Bool) {
//        fromTimePicker.isHidden = !displayed
//        toTimePicker.isHidden = !displayed
//        fromLabel.isHidden = !displayed
//        toLabel.isHidden = !displayed
//    }
//}

class PrefManager {
    static let sharedInstance = PrefManager()
    
    private init() {
        registerFactoryDefaults()
    }
    
    let userDefaults = UserDefaults.standard
    
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.isAutoLaunchEnabled: NSNumber(value: false),
            Keys.isStatusToggleEnabled: NSNumber(value: false),
            Keys.isDarkModeSyncEnabled: NSNumber(value: false),
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
        userDefaults.removeObject(forKey: Keys.isDarkModeSyncEnabled)
        userDefaults.removeObject(forKey: Keys.lastKnownLocation)
        userDefaults.removeObject(forKey: Keys.disabledApps)
        
        synchronize()
    }
}
