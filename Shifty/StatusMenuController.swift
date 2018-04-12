//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import MASShortcut
import AXSwift
import SwiftLog

class StatusMenuController: NSObject, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var sliderMenuItem: NSMenuItem!
    @IBOutlet weak var descriptionMenuItem: NSMenuItem!
    @IBOutlet weak var disableAppMenuItem: NSMenuItem!
    @IBOutlet weak var disableDomainMenuItem: NSMenuItem!
    @IBOutlet weak var disableSubdomainMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var disableCustomMenuItem: NSMenuItem!
    @IBOutlet weak var preferencesMenuItem: NSMenuItem!
    @IBOutlet weak var quitMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView! {
        didSet {
            sunIcon.image?.isTemplate = true
        }
    }
    @IBOutlet weak var moonIcon: NSImageView! {
        didSet {
            moonIcon.image?.isTemplate = true
        }
    }

    var preferencesWindow: NSWindowController!
    var prefGeneral: PrefGeneralViewController!
    var prefShortcuts: PrefShortcutsViewController!
    var customTimeWindow: CustomTimeWindow!
    
    var disabledUntilDate: Date?

    let calendar = NSCalendar(identifier: .gregorian)!

    //MARK: Menu life cycle

    override func awakeFromNib() {
        Log.logger.directory = "~/Library/Logs/Shifty"
        #if DEBUG
            Log.logger.name = "Shifty-debug"
        #else
            Log.logger.name = "Shifty"
        #endif
        //Edit printToConsole parameter in Edit Scheme > Run > Arguments > Environment Variables
        Log.logger.printToConsole = ProcessInfo.processInfo.environment["print_log"] == "true"

        statusMenu.delegate = self
        customTimeWindow = CustomTimeWindow()

        let prefWindow = (NSApplication.shared.delegate as? AppDelegate)?.preferenceWindowController
        prefGeneral = prefWindow?.viewControllers.flatMap { childViewController in
            return childViewController as? PrefGeneralViewController
        }.first
        prefShortcuts = prefWindow?.viewControllers.flatMap { childViewController in
            return childViewController as? PrefShortcutsViewController
        }.first

        descriptionMenuItem.isEnabled = false
        sliderMenuItem.view = sliderView

        disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
        disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        preferencesMenuItem.title = NSLocalizedString("menu.preferences", comment: "Preferences...")
        quitMenuItem.title = NSLocalizedString("menu.quit", comment: "Quit Shifty")

        sliderView.sliderValueChanged = { (sliderValue) in

        }

        sliderView.sliderEnabled = {

        }

        (NSApp.delegate as? AppDelegate)?.statusItemClicked = {

        }

        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            logw("Accessibility permissions changed: \(UIElement.isProcessTrusted(withPrompt: false))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    if UIElement.isProcessTrusted(withPrompt: false) {
                        UserDefaults.standard.set(true, forKey: Keys.isWebsiteControlEnabled)
                    } else {
                        UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
                    }
                })
        }

        prefShortcuts.bindShortcuts()
    }

    func menuWillOpen(_: NSMenu) {
        configureMenuItems()
        
        assignKeyboardShortcutToMenuItem(powerMenuItem, userDefaultsKey: Keys.toggleNightShiftShortcut)
        assignKeyboardShortcutToMenuItem(disableAppMenuItem, userDefaultsKey: Keys.disableAppShortcut)
        assignKeyboardShortcutToMenuItem(disableDomainMenuItem, userDefaultsKey: Keys.disableDomainShortcut)
        assignKeyboardShortcutToMenuItem(disableSubdomainMenuItem, userDefaultsKey: Keys.disableSubdomainShortcut)
        assignKeyboardShortcutToMenuItem(disableHourMenuItem, userDefaultsKey: Keys.disableHourShortcut)
        assignKeyboardShortcutToMenuItem(disableCustomMenuItem, userDefaultsKey: Keys.disableCustomShortcut)

        Event.menuOpened.record()
    }
    
    func configureMenuItems() {
        let currentAppName = RuleManager.currentApp?.localizedName ?? ""
        
        if NightShiftManager.isNightShiftEnabled {
            powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
        } else {
            powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
        }
        if RuleManager.disabledForApp {
            disableAppMenuItem.state = .on
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), currentAppName)
        } else {
            disableAppMenuItem.state = .off
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), currentAppName)
        }
        
        switch NightShiftManager.nightShiftDisableTimer {
        case .off:
            disableHourMenuItem.state = .off
            disableHourMenuItem.isEnabled = true
            disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
            
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.isEnabled = true
            disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        case .hour(timer: _):
            disableHourMenuItem.state = .on
            disableHourMenuItem.isEnabled = true
            disableHourMenuItem.title = NSLocalizedString("menu.disabled_hour", comment: "Disabled for an hour")
            
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.isEnabled = false
            disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        case .custom(timer: _):
            disableHourMenuItem.state = .off
            disableHourMenuItem.isEnabled = false
            disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
            
            disableCustomMenuItem.state = .on
            disableCustomMenuItem.isEnabled = true
            disableCustomMenuItem.title = NSLocalizedString("menu.disabled_custom", comment: "Disabled for custom time")
        }
    }

    func assignKeyboardShortcutToMenuItem(_ menuItem: NSMenuItem, userDefaultsKey: String) {
        if let data = UserDefaults.standard.value(forKey: userDefaultsKey),
            let shortcut = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as? MASShortcut {
            let flags = NSEvent.ModifierFlags.init(rawValue: shortcut.modifierFlags)
            menuItem.keyEquivalentModifierMask = flags
            menuItem.keyEquivalent = shortcut.keyCodeString.lowercased()
        } else {
            menuItem.keyEquivalentModifierMask = []
            menuItem.keyEquivalent = ""
        }
    }


    //MARK: Handle states

    //MARK: User Interaction

    @IBAction func power(_ sender: Any) {
        if NightShiftManager.isNightShiftEnabled {
            NightShiftManager.respond(to: .userDisabledNightShift)
        } else {
            NightShiftManager.respond(to: .userEnabledNightShift)
        }
    }

    @IBAction func disableForApp(_ sender: Any) {
        if RuleManager.disabledForApp {
            RuleManager.disabledForApp = false
            NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)
        } else {
            RuleManager.disabledForApp = true
            NightShiftManager.respond(to: .nightShiftDisableRuleActivated)
        }
        Event.disableForCurrentApp(state: (sender as? NSMenuItem)?.state == .on).record()
    }

    @IBAction func disableForDomain(_ sender: Any) {

    }

    @IBAction func disableForSubdomain(_ sender: Any) {
        
    }
    
    @IBAction func disableHour(_ sender: Any) {
        if disableHourMenuItem.state == .off {
            let disableTimer = Timer(timeInterval: 3600, repeats: false) { _ in
                NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
            
            NightShiftManager.nightShiftDisableTimer = .hour(timer: disableTimer)
            NightShiftManager.respond(to: .nightShiftDisableTimerStarted)
        } else {
            NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
        }
    }

    @IBAction func disableCustomTime(_ sender: Any) {
        if disableCustomMenuItem.state == .off {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
            
            customTimeWindow.disableCustomTime = { (timeIntervalInSeconds) in
                let disableTimer = Timer(timeInterval: TimeInterval(timeIntervalInSeconds), repeats: false) { _ in
                    NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
                }
                disableTimer.tolerance = 60
                
                let currentDate = Date()
                var addComponents = DateComponents()
                addComponents.second = timeIntervalInSeconds
                self.disabledUntilDate = self.calendar.date(byAdding: addComponents, to: currentDate, options: [])!
                
                NightShiftManager.nightShiftDisableTimer = .custom(timer: disableTimer)
                NightShiftManager.respond(to: .nightShiftDisableTimerStarted)
            }
        } else {
            NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
        }
    }

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        (NSApp.delegate as? AppDelegate)?.preferenceWindowController.showWindow(sender)

        Event.preferencesWindowOpened.record()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
        NightShiftManager.respond(to: .nightShiftDisableRuleDeactivated)

        Event.quitShifty.record()
        NotificationCenter.default.post(name: .terminateApp, object: self)
        
        NSApplication.shared.terminate(self)
    }


    //MARK: Helper functions
}
