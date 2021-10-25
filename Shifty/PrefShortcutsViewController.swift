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
        return "PrefShortcutsViewController"
    }

    var viewIdentifier: String = "PrefShortcutsViewController"

    var toolbarItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "command", accessibilityDescription: nil)
        } else {
            return #imageLiteral(resourceName: "shortcutsIcon")
        }
    }

    var toolbarItemLabel: String? {
        view.layoutSubtreeIfNeeded()
        return NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
    }

    var hasResizableWidth = false
    var hasResizableHeight = false
    
    @IBOutlet weak var toggleTrueToneLabel: NSTextField!
    
    @IBOutlet weak var toggleNightShiftShortcut: MASShortcutView!
    @IBOutlet weak var incrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var decrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var disableAppShortcut: MASShortcutView!
    @IBOutlet weak var disableDomainShortcut: MASShortcutView!
    @IBOutlet weak var disableSubdomainShortcut: MASShortcutView!
    @IBOutlet weak var disableHourShortcut: MASShortcutView!
    @IBOutlet weak var disableCustomShortcut: MASShortcutView!
    @IBOutlet weak var toggleTrueToneShortcut: MASShortcutView!
    @IBOutlet weak var toggleDarkModeShortcut: MASShortcutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }
        
        //Hide True Tone settings on unsupported computers
        if #available(macOS 10.14, *) {
            let trueToneUnsupported = CBTrueToneClient.shared.state == .unsupported
            toggleTrueToneLabel.isHidden = trueToneUnsupported
            toggleTrueToneShortcut.isHidden = trueToneUnsupported
        } else {
            toggleTrueToneLabel.isHidden = true
            toggleTrueToneShortcut.isHidden = true
        }


        toggleNightShiftShortcut.associatedUserDefaultsKey = Keys.toggleNightShiftShortcut
        incrementColorTempShortcut.associatedUserDefaultsKey = Keys.incrementColorTempShortcut
        decrementColorTempShortcut.associatedUserDefaultsKey = Keys.decrementColorTempShortcut
        disableAppShortcut.associatedUserDefaultsKey = Keys.disableAppShortcut
        disableDomainShortcut.associatedUserDefaultsKey = Keys.disableDomainShortcut
        disableSubdomainShortcut.associatedUserDefaultsKey = Keys.disableSubdomainShortcut
        disableHourShortcut.associatedUserDefaultsKey = Keys.disableHourShortcut
        disableCustomShortcut.associatedUserDefaultsKey = Keys.disableCustomShortcut
        toggleTrueToneShortcut.associatedUserDefaultsKey = Keys.toggleTrueToneShortcut
        toggleDarkModeShortcut.associatedUserDefaultsKey = Keys.toggleDarkModeShortcut
    }

    override func viewWillDisappear() {
        Event.shortcuts(toggleNightShift: toggleNightShiftShortcut.shortcutValue != nil,
                        increaseColorTemp: incrementColorTempShortcut.shortcutValue != nil,
                        decreaseColorTemp: decrementColorTempShortcut.shortcutValue != nil,
                        disableApp: disableAppShortcut.shortcutValue != nil,
                        disableDomain: disableDomainShortcut.shortcutValue != nil,
                        disableSubdomain: disableSubdomainShortcut.shortcutValue != nil,
                        disableHour: disableHourShortcut.shortcutValue != nil,
                        disableCustom: disableCustomShortcut.shortcutValue != nil,
                        toggleTrueTone: toggleTrueToneShortcut.shortcutValue != nil,
                        toggleDarkMode: toggleDarkModeShortcut.shortcutValue != nil).record()
    }

    func bindShortcuts() {
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.toggleNightShiftShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.powerMenuItem.isHidden && menu.powerMenuItem.isEnabled {
                self.statusMenuController?.power(self)
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.incrementColorTempShortcut) {
            if NightShiftManager.shared.isNightShiftEnabled {
                if NightShiftManager.shared.colorTemperature == 1.0 {
                    NSSound.beep()
                }
                NightShiftManager.shared.colorTemperature += 0.1
            } else {
                NightShiftManager.shared.respond(to: .userEnabledNightShift)
                NightShiftManager.shared.colorTemperature = 0.1
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.decrementColorTempShortcut) {
            if NightShiftManager.shared.isNightShiftEnabled {
                NightShiftManager.shared.colorTemperature -= 0.1
                if NightShiftManager.shared.colorTemperature == 0.0 {
                    NSSound.beep()
                }
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableAppShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.disableAppMenuItem.isHidden && menu.disableAppMenuItem.isEnabled {
                self.statusMenuController?.disableForApp(self)
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableDomainShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.disableDomainMenuItem.isHidden && menu.disableDomainMenuItem.isEnabled {
                self.statusMenuController?.disableForDomain(self)
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableSubdomainShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.disableSubdomainMenuItem.isHidden && menu.disableSubdomainMenuItem.isEnabled {
                self.statusMenuController?.disableForSubdomain(self)
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableHourShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.disableHourMenuItem.isHidden && menu.disableHourMenuItem.isEnabled {
                self.statusMenuController?.disableHour(self)
            } else {
                NSSound.beep()
            }
        }

        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableCustomShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.disableCustomMenuItem.isHidden && menu.disableCustomMenuItem.isEnabled {
                self.statusMenuController?.disableCustomTime(self)
            } else {
                NSSound.beep()
            }
        }
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.toggleTrueToneShortcut) {
            guard let menu = self.statusMenuController else { return }
            if !menu.trueToneMenuItem.isHidden && menu.trueToneMenuItem.isEnabled {
                self.statusMenuController?.toggleTrueTone(self)
            } else {
                NSSound.beep()
            }
        }
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.toggleDarkModeShortcut, toAction: {
            SLSSetAppearanceThemeLegacy(!SLSGetAppearanceThemeLegacy())
        })
    }
}
