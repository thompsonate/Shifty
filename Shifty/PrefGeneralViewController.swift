//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences_Shifty
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
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.preferencesGeneralName)
        }
    }

    var toolbarItemLabel: String? {
        view.layoutSubtreeIfNeeded()
        return NSLocalizedString("prefs.general", comment: "General")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    @IBOutlet weak var autoLaunchButton: NSButton!
    @IBOutlet weak var quickToggleButton: NSButton!
    @IBOutlet weak var iconSwitchingButton: NSButton!
    @IBOutlet weak var darkModeSyncButton: NSButton!
    @IBOutlet weak var websiteShiftingButton: NSButton!
    @IBOutlet weak var trueToneControlButton: NSButton!
    
    @IBOutlet weak var trueToneStackView: NSStackView!
    
    @IBOutlet weak var schedulePopup: NSPopUpButton!
    @IBOutlet weak var offMenuItem: NSMenuItem!
    @IBOutlet weak var customMenuItem: NSMenuItem!
    @IBOutlet weak var sunMenuItem: NSMenuItem!

    @IBOutlet weak var fromTimePicker: NSDatePicker!
    @IBOutlet weak var toTimePicker: NSDatePicker!
    @IBOutlet weak var fromLabel: NSTextField!
    @IBOutlet weak var toLabel: NSTextField!
    @IBOutlet weak var customTimeStackView: NSStackView!

    var appDelegate: AppDelegate!
    var prefWindow: NSWindow!
    
    var defaultDarkModeState: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        prefWindow = appDelegate.preferenceWindowController.window
        
        NightShiftManager.shared.onNightShiftChange {
            self.updateSchedule()
        }

        //Hide True Tone settings on unsupported computers
        if #available(macOS 10.14, *) {
            trueToneStackView.isHidden = CBTrueToneClient.shared.state == .unsupported
        } else {
            trueToneStackView.isHidden = true
        }
        
        defaultDarkModeState = SLSGetAppearanceThemeLegacy()

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        updateSchedule()
    }
    
    func updateSchedule() {
        switch NightShiftManager.shared.schedule {
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

    //MARK: IBActions

    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, sender.state == .on)
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
            defaultDarkModeState = SLSGetAppearanceThemeLegacy()
            NightShiftManager.shared.updateDarkMode()
        } else {
            SLSSetAppearanceThemeLegacy(defaultDarkModeState)
        }
        logw("Dark mode sync preference set to \(sender.state.rawValue)")
    }

    @IBAction func setWebsiteControl(_ sender: NSButtonCell) {
        logw("Website control preference clicked")
        if sender.state == .on {
            if !UIElement.isProcessTrusted() {
                logw("Accessibility permissions alert shown")

                UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
                NSApp.runModal(for: AccessibilityWindow().window!)
            }
        } else {
            BrowserManager.shared.stopBrowserWatcher()
            logw("Website control disabled")
        }
    }
    
    @IBAction func setTrueToneControl(_ sender: NSButtonCell) {
        if #available(macOS 10.14, *) {
            if sender.state == .on {
                if NightShiftManager.shared.isDisableRuleActive {
                    CBTrueToneClient.shared.isTrueToneEnabled = false
                }
            } else {
                CBTrueToneClient.shared.isTrueToneEnabled = true
            }
            logw("True Tone control set to \(sender.state.rawValue)")
        }
    }
    
    @IBAction func analyticsDetailClicked(_ sender: Any) {
        self.presentAsSheet(AnalyticsDetailViewController())
    }
    
    @IBAction func schedulePopup(_ sender: NSPopUpButton) {
        if schedulePopup.selectedItem == offMenuItem {
            NightShiftManager.shared.schedule = .off
            customTimeStackView.isHidden = true
        } else if schedulePopup.selectedItem == customMenuItem {
            scheduleTimePickers(self)
            customTimeStackView.isHidden = false
        } else if schedulePopup.selectedItem == sunMenuItem {
            NightShiftManager.shared.schedule = .solar
            customTimeStackView.isHidden = true
        }
    }

    @IBAction func scheduleTimePickers(_ sender: Any) {
        let fromTime = Time(fromTimePicker.dateValue)
        let toTime = Time(toTimePicker.dateValue)
        NightShiftManager.shared.schedule = .custom(start: fromTime, end: toTime)
    }

    override func viewWillDisappear() {
        Event.preferences(autoLaunch: autoLaunchButton.state == .on,
                          quickToggle: quickToggleButton.state == .on,
                          iconSwitching: iconSwitchingButton.state == .on,
                          syncDarkMode: darkModeSyncButton.state == .on,
                          websiteShifting: websiteShiftingButton.state == .on,
                          trueToneControl: trueToneControlButton.state == .on,
                          schedule: NightShiftManager.shared.schedule).record()
    }
}


class PrefWindowController: MASPreferencesWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.styleMask = [.titled, .closable]
        
        if #available(macOS 11.0, *) {
            window?.toolbarStyle = .preference
        }
    }
    
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            window?.close()
        }
    }
}
