//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences
import ServiceManagement

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
    
    @IBOutlet weak var setAutoLaunch: NSButton!
    @IBOutlet weak var toggleStatusItem: NSButton!
    @IBOutlet weak var darkModeSync: NSButton!
    
    @IBOutlet weak var schedulePopup: NSPopUpButton!
    @IBOutlet weak var offMenuItem: NSMenuItem!
    @IBOutlet weak var customMenuItem: NSMenuItem!
    @IBOutlet weak var sunMenuItem: NSMenuItem!
    
    @IBOutlet weak var fromTimePicker: NSDatePicker!
    @IBOutlet weak var toTimePicker: NSDatePicker!
    @IBOutlet weak var fromLabel: NSTextField!
    @IBOutlet weak var toLabel: NSTextField!
    
    let prefs = UserDefaults.standard
    var setStatusToggle: (() -> Void)?
    var updateSchedule: (() -> Void)?
    var updateDarkMode: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSchedule = {
            switch BLClient.schedule {
            case .off:
                self.schedulePopup.select(self.offMenuItem)
                self.showScheduleDates(displayed: false)
            case .timedSchedule(startTime: let startTime, endTime: let endTime):
                self.schedulePopup.select(self.customMenuItem)
                self.fromTimePicker.dateValue = startTime
                self.toTimePicker.dateValue = endTime
                self.showScheduleDates(displayed: true)
            case .sunSchedule:
                self.schedulePopup.select(self.sunMenuItem)
                self.showScheduleDates(displayed: false)
            }
        }
        
        updateSchedule?()
    }
    
    //MARK: IBActions
    
    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let autoLaunch = setAutoLaunch.state == .on
        prefs.setValue(autoLaunch, forKey: Keys.isAutoLaunchEnabled)
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, autoLaunch)
    }
    
    @IBAction func quickToggle(_ sender: NSButtonCell) {
        let quickToggle = toggleStatusItem.state == .on
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        prefs.setValue(quickToggle, forKey: Keys.isStatusToggleEnabled)
        appDelegate.setStatusToggle()
    }
    
    @IBAction func syncDarkMode(_ sender: NSButtonCell) {
        updateDarkMode!()
        if !UserDefaults.standard.bool(forKey: Keys.isDarkModeSyncEnabled) {
            SLSSetAppearanceThemeLegacy(false)
        }
    }
    
    @IBAction func schedulePopup(_ sender: Any) {
        if schedulePopup.selectedItem == offMenuItem {
            BLClient.setSchedule(.off)
            showScheduleDates(displayed: false)
        } else if schedulePopup.selectedItem == customMenuItem {
            BLClient.setMode(2)
            showScheduleDates(displayed: true)
        } else if schedulePopup.selectedItem == sunMenuItem {
            BLClient.setMode(1)
            showScheduleDates(displayed: false)
        }
    }
    
    @IBAction func scheduleTimePickers(_ sender: Any) {
        let fromTime = fromTimePicker.dateValue
        let toTime = toTimePicker.dateValue
        BLClient.setSchedule(.timedSchedule(startTime: fromTime, endTime: toTime))
    }
    
    func showScheduleDates(displayed: Bool) {
        fromTimePicker.isHidden = !displayed
        toTimePicker.isHidden = !displayed
        fromLabel.isHidden = !displayed
        toLabel.isHidden = !displayed
    }
}


extension MASPreferencesWindowController {
    override open func keyDown(with theEvent: NSEvent) {
        if theEvent.keyCode == 13 {
            window?.close()
        }
    }
}


