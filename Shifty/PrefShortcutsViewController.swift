//
//  PrefShortcutsViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences_Shifty
import MASShortcut

@objcMembers
class PrefShortcutsViewController: NSViewController, MASPreferencesViewController {

    let statusMenuController = (NSApplication.shared.delegate as? AppDelegate)?.statusMenu.delegate as? StatusMenuController

    override var nibName: NSNib.Name {
        return NSNib.Name("PrefShortcutsViewController")
    }

    var viewIdentifier: String = "PrefShortcutsViewController"

    var toolbarItemImage: NSImage? {
        return #imageLiteral(resourceName: "shortcutsIcon")
    }

    var toolbarItemLabel: String? {
        view.layoutSubtreeIfNeeded()
        return NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    @IBOutlet weak var toggleNightShiftShortcut: MASShortcutView!
    @IBOutlet weak var incrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var decrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var disableAppShortcut: MASShortcutView!
    @IBOutlet weak var disableHourShortcut: MASShortcutView!
    @IBOutlet weak var disableCustomShortcut: MASShortcutView!

    override func viewDidLoad() {
        super.viewDidLoad()

        toggleNightShiftShortcut.associatedUserDefaultsKey = Keys.toggleNightShiftShortcut
        incrementColorTempShortcut.associatedUserDefaultsKey = Keys.incrementColorTempShortcut
        decrementColorTempShortcut.associatedUserDefaultsKey = Keys.decrementColorTempShortcut
        disableAppShortcut.associatedUserDefaultsKey = Keys.disableAppShortcut
        disableHourShortcut.associatedUserDefaultsKey = Keys.disableHourShortcut
        disableCustomShortcut.associatedUserDefaultsKey = Keys.disableCustomShortcut
    }

    override func viewWillDisappear() {
        Event.shortcuts(toggleNightShift: toggleNightShiftShortcut.shortcutValue != nil, increaseColorTemp: incrementColorTempShortcut.shortcutValue != nil, decreaseColorTemp: decrementColorTempShortcut.shortcutValue != nil, disableApp: disableAppShortcut.shortcutValue != nil, disableHour: disableHourShortcut.shortcutValue != nil, disableCustom: disableCustomShortcut.shortcutValue != nil).record()
    }

    func bindShortcuts() {
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.toggleNightShiftShortcut) {
            self.statusMenuController?.power(self)
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.incrementColorTempShortcut) {
            if NightShiftManager.isNightShiftEnabled {
                if NightShiftManager.blueLightReductionAmount == 1.0 {
                    NSSound.beep()
                }
                NightShiftManager.blueLightReductionAmount += 0.1
            } else {
                NightShiftManager.respond(to: .userEnabledNightShift)
                NightShiftManager.blueLightReductionAmount = 0.1
//                self.statusMenuController?.disableDisableTimer()
//                if self.statusMenuController?.isDisabledForApp ?? false {
//                    NSSound.beep()
//                }
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.decrementColorTempShortcut) {
            if NightShiftManager.isNightShiftEnabled {
                NightShiftManager.blueLightReductionAmount -= 0.1
                if NightShiftManager.blueLightReductionAmount == 0.0 {
//                    BLClient.setEnabled(false)
                }
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableAppShortcut) {
            self.statusMenuController?.disableForApp(self)
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableHourShortcut) {
//            if NightShiftManager.isNightShiftEnabled || (self.statusMenuController?.isDisableHourSelected) ?? false {
//                self.statusMenuController?.disableHour(self)
//            } else {
//                NSSound.beep()
//            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableCustomShortcut) {
//            if NightShiftManager.isNightShiftEnabled || (self.statusMenuController?.isDisableCustomSelected) ?? false {
//                self.statusMenuController?.disableCustomTime(self)
//            } else {
//                NSSound.beep()
//            }
        }
    }
}
