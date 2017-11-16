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
            return "Shortcuts"
        }
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
    
    func bindShortcuts() {
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.toggleNightShiftShortcut) {
            self.statusMenuController?.power(self)
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
            self.statusMenuController?.disableForApp(self)
        }
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableHourShortcut) {
            if BLClient.isNightShiftEnabled || (self.statusMenuController?.isDisableHourSelected) ?? false {
                self.statusMenuController?.disableHour(self)
            } else {
                NSSound.beep()
            }
        }
        
        MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Keys.disableCustomShortcut) {
            if BLClient.isNightShiftEnabled || (self.statusMenuController?.isDisableCustomSelected) ?? false {
                self.statusMenuController?.disableCustomTime(self)
            } else {
                NSSound.beep()
            }
        }
    }
}
