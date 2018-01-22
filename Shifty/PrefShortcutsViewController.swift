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
        get { return NSNib.Name("PrefShortcutsViewController") }
    }
    
    var viewIdentifier: String = "PrefShortcutsViewController"
    
    var toolbarItemImage: NSImage? {
        get { return #imageLiteral(resourceName: "shortcutsIcon") }
    }
    
    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
        }
    }
    
    var hasResizableWidth = false
    var hasResizableHeight = false
    
    @IBOutlet weak var toggleNightShiftShortcut: MASShortcutView!
    @IBOutlet weak var incrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var decrementColorTempShortcut: MASShortcutView!
    @IBOutlet weak var disableAppShortcut: MASShortcutView!
    @IBOutlet weak var disableDomainShortcut: MASShortcutView!
    @IBOutlet weak var disableSubdomainShortcut: MASShortcutView!
    @IBOutlet weak var disableHourShortcut: MASShortcutView!
    @IBOutlet weak var disableCustomShortcut: MASShortcutView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }
        
        toggleNightShiftShortcut.associatedUserDefaultsKey = Keys.toggleNightShiftShortcut
        incrementColorTempShortcut.associatedUserDefaultsKey = Keys.incrementColorTempShortcut
        decrementColorTempShortcut.associatedUserDefaultsKey = Keys.decrementColorTempShortcut
        disableAppShortcut.associatedUserDefaultsKey = Keys.disableAppShortcut
        disableDomainShortcut.associatedUserDefaultsKey = Keys.disableDomainShortcut
        disableSubdomainShortcut.associatedUserDefaultsKey = Keys.disableSubdomainShortcut
        disableHourShortcut.associatedUserDefaultsKey = Keys.disableHourShortcut
        disableCustomShortcut.associatedUserDefaultsKey = Keys.disableCustomShortcut
    }
    
    override func viewWillDisappear() {
        Event.shortcuts(toggleNightShift: toggleNightShiftShortcut.shortcutValue != nil, increaseColorTemp: incrementColorTempShortcut.shortcutValue != nil, decreaseColorTemp: decrementColorTempShortcut.shortcutValue != nil, disableApp: disableAppShortcut.shortcutValue != nil, disableDomain: disableDomainShortcut.shortcutValue != nil, disableSubdomain: disableSubdomainShortcut.shortcutValue != nil, disableHour: disableHourShortcut.shortcutValue != nil, disableCustom: disableCustomShortcut.shortcutValue != nil).record()
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
            if BLClient.isNightShiftEnabled {
                if BLClient.strength == 1.0 {
                    NSSound.beep()
                }
                BLClient.setStrength(BLClient.strength + 0.1, commit: true)
            } else {
                BLClient.setEnabled(true)
                BLClient.setStrength(0.1, commit: true)
                self.statusMenuController?.disableDisableTimer()
                if self.statusMenuController?.isDisabledForApp ?? false {
                    NSSound.beep()
                }
            }
        }
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.decrementColorTempShortcut) {
            if BLClient.isNightShiftEnabled {
                BLClient.setStrength(BLClient.strength - 0.1, commit: true)
                if BLClient.strength == 0.0 {
                    BLClient.setEnabled(false)
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
    }
}
