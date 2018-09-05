//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences
import ServiceManagement
import AXSwift
import SwiftLog


@objcMembers
class PrefGeneralViewController: NSViewController, MASPreferencesViewController {

    override var nibName: NSNib.Name {
        return "PrefGeneralViewController"
    }

    var viewIdentifier: String = "PrefGeneralViewController"

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImage.preferencesGeneralName)
    }

    var toolbarItemLabel: String? {
        view.layoutSubtreeIfNeeded()
        return NSLocalizedString("prefs.general", comment: "General")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    @IBOutlet weak var setAutoLaunch: NSButton!
    @IBOutlet weak var toggleStatusItem: NSButton!
    @IBOutlet weak var setIconSwitching: NSButton!
    @IBOutlet weak var darkModeSync: NSButton!
    @IBOutlet weak var websiteShifting: NSButton!

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

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }

        updateSchedule = {
            switch NightShiftManager.schedule {
            case .off:
                self.schedulePopup.select(self.offMenuItem)
                self.customTimeStackView.isHidden = true
            case .custom(start: let startTime, end: let endTime):
                self.schedulePopup.select(self.customMenuItem)
                let startDate = Date(startTime)
                let endDate = Date(endTime)
                
                self.fromTimePicker.dateValue = startDate
                self.toTimePicker.dateValue = endDate
                self.customTimeStackView.isHidden = false
            case .solar:
                self.schedulePopup.select(self.sunMenuItem)
                self.customTimeStackView.isHidden = true
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        updateSchedule?()
    }

    //MARK: IBActions

    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, setAutoLaunch.state == .on)
        logw("Auto launch on login set to \(sender.state.rawValue)")
    }

    @IBAction func quickToggle(_ sender: NSButtonCell) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.setStatusToggle()
        logw("Quick Toggle set to \(sender.state.rawValue)")
    }

    @IBAction func setIconSwitching(_ sender: NSButtonCell) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.updateMenuBarIcon()
        logw("Icon switching set to \(sender.state.rawValue)")
    }

    @IBAction func syncDarkMode(_ sender: NSButtonCell) {
        if sender.state == .on {
            NightShiftManager.updateDarkMode()
        } else {
            SLSSetAppearanceThemeLegacy(false)
        }
        logw("Dark mode sync preference set to \(sender.state.rawValue)")
    }

    @IBAction func setWebsiteControl(_ sender: NSButtonCell) {
        logw("Website control preference clicked")
        if sender.state == .on {
            if !UIElement.isProcessTrusted() {
                logw("Accessibility permissions alert shown")

                prefs.set(false, forKey: Keys.isWebsiteControlEnabled)
                NSApp.runModal(for: AccessibilityWindow().window!)
            }
        } else {
            BrowserManager.stopBrowserWatcher()
            logw("Website control disabled")
        }
    }
    
    @IBAction func setTrueToneControl(_ sender: NSButtonCell) {
        if sender.state == .on {
            if NightShiftManager.disableRuleIsActive {
                CBTrueToneClient.shared.isTrueToneEnabled = false
            }
        } else {
            CBTrueToneClient.shared.isTrueToneEnabled = true
        }
        logw("True Tone control set to \(sender.state.rawValue)")
    }
    
    @IBAction func schedulePopup(_ sender: NSPopUpButton) {
        if schedulePopup.selectedItem == offMenuItem {
            NightShiftManager.schedule = .off
            customTimeStackView.isHidden = true
        } else if schedulePopup.selectedItem == customMenuItem {
            scheduleTimePickers(self)
            customTimeStackView.isHidden = false
        } else if schedulePopup.selectedItem == sunMenuItem {
            NightShiftManager.schedule = .solar
            customTimeStackView.isHidden = true
        }
    }

    @IBAction func scheduleTimePickers(_ sender: Any) {
        let fromTime = Time(fromTimePicker.dateValue)
        let toTime = Time(toTimePicker.dateValue)
        NightShiftManager.schedule = .custom(start: fromTime, end: toTime)
    }

    override func viewWillDisappear() {
        Event.preferences(autoLaunch: setAutoLaunch.state == .on,
                          quickToggle: toggleStatusItem.state == .on,
                          iconSwitching: setIconSwitching.state == .on,
                          syncDarkMode: darkModeSync.state == .on,
                          websiteShifting: websiteShifting.state == .on,
                          schedule: NightShiftManager.schedule).record()
    }
}


class PrefWindowController: MASPreferencesWindowController {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            window?.close()
        }
    }
}
