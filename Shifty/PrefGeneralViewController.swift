//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences_Shifty
import ServiceManagement

///The height difference between the custom schedule controls being shown and hidden
let PREF_GENERAL_HEIGHT_ADJUSTMENT = CGFloat(33.0)

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
    @IBOutlet weak var customTimeStackView: NSStackView!
    
    let prefs = UserDefaults.standard
    var setStatusToggle: (() -> Void)?
    var updateSchedule: (() -> Void)?
    var updateDarkMode: (() -> Void)?
    
    var appDelegate: AppDelegate!
    var prefWindow: NSWindow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = NSApplication.shared.delegate as! AppDelegate
        prefWindow = appDelegate.preferenceWindowController.window
        
        updateSchedule = {
            switch BLClient.schedule {
            case .off:
                self.schedulePopup.select(self.offMenuItem)
                self.setCustomControlVisibility(false, animate: false)
            case .timedSchedule(startTime: let startTime, endTime: let endTime):
                self.schedulePopup.select(self.customMenuItem)
                self.fromTimePicker.dateValue = startTime
                self.toTimePicker.dateValue = endTime
                self.setCustomControlVisibility(true, animate: false)
            case .sunSchedule:
                self.schedulePopup.select(self.sunMenuItem)
                self.setCustomControlVisibility(false, animate: false)
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
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
            setCustomControlVisibility(false, animate: true)
        } else if schedulePopup.selectedItem == customMenuItem {
            BLClient.setMode(2)
            setCustomControlVisibility(true, animate: true)
        } else if schedulePopup.selectedItem == sunMenuItem {
            BLClient.setMode(1)
            setCustomControlVisibility(false, animate: true)
            
        }
    }
    
    @IBAction func scheduleTimePickers(_ sender: Any) {
        let fromTime = fromTimePicker.dateValue
        let toTime = toTimePicker.dateValue
        BLClient.setSchedule(.timedSchedule(startTime: fromTime, endTime: toTime))
    }
    
    func setCustomControlVisibility(_ visible: Bool, animate: Bool) {
        var adjustment = PREF_GENERAL_HEIGHT_ADJUSTMENT
        if customTimeStackView.isHidden == visible || (!visible && !animate)  {
            if let frame = prefWindow?.frame {
                if visible {
                    //Keep elements hidden until after animation is completed
                    fromLabel.isHidden = true
                    fromTimePicker.isHidden = true
                    toLabel.isHidden = true
                    toTimePicker.isHidden = true
                } else {
                    adjustment *= -1
                }
                
                customTimeStackView.isHidden = !visible
                let newFrame = NSMakeRect(frame.origin.x, frame.origin.y - adjustment, frame.width, frame.height + adjustment)
                prefWindow.setFrame(newFrame, display: true, animate: animate)
                
                if visible {
                    fromLabel.isHidden = false
                    fromTimePicker.isHidden = false
                    toLabel.isHidden = false
                    toTimePicker.isHidden = false
                }
            }
        }
    }
}


class PrefWindowController: MASPreferencesWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = .floating
    }
    
    override func keyDown(with theEvent: NSEvent) {
        if theEvent.keyCode == 13 {
            window?.close()
        }
    }
    
    //Decreases window frame height if custom schedule controls are not shown
    override func getNewWindowFrame() -> NSRect {
        if BLClient.isOffSchedule || BLClient.isSunSchedule {
            let newFrame = super.getNewWindowFrame()
            return NSMakeRect(newFrame.origin.x, newFrame.origin.y + PREF_GENERAL_HEIGHT_ADJUSTMENT, newFrame.width, newFrame.height - PREF_GENERAL_HEIGHT_ADJUSTMENT)
        } else {
            return super.getNewWindowFrame()
        }
    }
}
