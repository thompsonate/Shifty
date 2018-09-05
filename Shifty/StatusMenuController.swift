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
    @IBOutlet weak var trueToneMenuItem: NSMenuItem!
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
        prefGeneral = prefWindow?.viewControllers.compactMap { childViewController in
            return childViewController as? PrefGeneralViewController
        }.first
        prefShortcuts = prefWindow?.viewControllers.compactMap { childViewController in
            return childViewController as? PrefShortcutsViewController
        }.first
        
        

        descriptionMenuItem.isEnabled = false
        sliderMenuItem.view = sliderView

        disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
        disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        preferencesMenuItem.title = NSLocalizedString("menu.preferences", comment: "Preferences...")
        quitMenuItem.title = NSLocalizedString("menu.quit", comment: "Quit Shifty")
        
        if CBTrueToneClient.shared.isTrueToneSupported {
            if CBTrueToneClient.shared.isTrueToneEnabled {
                trueToneMenuItem.title = "Turn off True Tone"
            } else {
                trueToneMenuItem.title = "Turn on True Tone"
            }
            trueToneMenuItem.isEnabled = CBTrueToneClient.shared.isTrueToneAvailable
        } else {
            trueToneMenuItem.isHidden = true
        }
        
        

        (NSApp.delegate as? AppDelegate)?.statusItemClicked = {
            if NightShiftManager.isNightShiftEnabled {
                NightShiftManager.respond(to: .userDisabledNightShift)
            } else {
                NightShiftManager.respond(to: .userEnabledNightShift)
            }
        }

        prefShortcuts.bindShortcuts()
    }
    
    
    

    func menuWillOpen(_: NSMenu) {
        configureMenuItems()
        setDescriptionText()
        
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
        
        sliderView.shiftSlider.floatValue = NightShiftManager.blueLightReductionAmount * 100
        
        if NightShiftManager.isNightShiftEnabled {
            powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
            sliderView.shiftSlider.isEnabled = true
        } else {
            powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
            sliderView.shiftSlider.isEnabled = false
        }
        
        if RuleManager.disabledForApp {
            disableAppMenuItem.state = .on
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), currentAppName)
        } else {
            disableAppMenuItem.state = .off
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), currentAppName)
        }
        
        if BrowserManager.hasValidDomain {
            disableDomainMenuItem.isHidden = false
            if RuleManager.disabledForDomain {
                disableDomainMenuItem.state = .on
                disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), BrowserManager.currentDomain ?? "")
            } else {
                disableDomainMenuItem.state = .off
                disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), BrowserManager.currentDomain ?? "")
            }
        } else {
            disableDomainMenuItem.isHidden = true
        }
        
        if BrowserManager.hasValidSubdomain {
            disableSubdomainMenuItem.isHidden = false
            if RuleManager.ruleForSubdomain == .enabled {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enabled_for", comment: "Enabled for %@"), BrowserManager.currentSubdomain ?? "")
            } else if RuleManager.ruleForSubdomain == .disabled {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), BrowserManager.currentSubdomain ?? "")
            } else if RuleManager.disabledForDomain {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enable_for", comment: "Enable for %@"), BrowserManager.currentSubdomain ?? "")
            } else {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), BrowserManager.currentSubdomain ?? "")
            }
        } else {
            disableSubdomainMenuItem.isHidden = true
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
    
    
    
    
    func setDescriptionText(keepVisible: Bool = false) {
        if NightShiftManager.disabledTimer {
            var disabledUntilDate: Date
            
            switch NightShiftManager.nightShiftDisableTimer {
            case .hour(timer: _, endDate: let date), .custom(timer: _, endDate: let date):
                disabledUntilDate = date
            case .off:
                return
            }
            
            let nowDate = Date()
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = [.second]
            let disabledTimeLeftComponents = calendar.components([.second], from: nowDate, to: disabledUntilDate, options: [])
            var disabledHoursLeft = (Double(disabledTimeLeftComponents.second!) / 3600.0).rounded(.down)
            var disabledMinutesLeft = (Double(disabledTimeLeftComponents.second!) / 60.0).truncatingRemainder(dividingBy: 60.0).rounded(.toNearestOrEven)
            
            if disabledMinutesLeft == 60.0 {
                disabledMinutesLeft = 0.0
                disabledHoursLeft += 1.0
            }
            
            if disabledHoursLeft > 0 {
                descriptionMenuItem.title = String(format: NSLocalizedString("description.disabled_hours_minutes", comment: "Disabled for %02d:%02d"), Int(disabledHoursLeft), Int(disabledMinutesLeft))
            } else {
                descriptionMenuItem.title = localizedPlural("menu.disabled_time", count: Int(disabledMinutesLeft), comment: "The number of minutes left when disabled for a set amount of time.")
            }
            descriptionMenuItem.isHidden = false
            return
        }
        
        switch NightShiftManager.schedule {
        case .off:
            if keepVisible {
                descriptionMenuItem.title = NSLocalizedString("description.enabled", comment: "Enabled")
            } else {
                descriptionMenuItem.isHidden = true
            }
        case .solar:
            if !keepVisible {
                descriptionMenuItem.isHidden = !NightShiftManager.isNightShiftEnabled
            }
            if NightShiftManager.isNightShiftEnabled {
                descriptionMenuItem.title = NSLocalizedString("description.enabled_sunrise", comment: "Enabled until sunrise")
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled", comment: "Disabled")
            }
        case .custom(_, let endTime):
            if !keepVisible {
                descriptionMenuItem.isHidden = !NightShiftManager.isNightShiftEnabled
            }
            if NightShiftManager.isNightShiftEnabled {
                let dateFormatter = DateFormatter()
                
                if Bundle.main.preferredLocalizations.first == "zh-Hans" {
                    dateFormatter.dateFormat = "a hh:mm "
                } else {
                    dateFormatter.dateStyle = .none
                    dateFormatter.timeStyle = .short
                }
                
                let date = dateFormatter.string(from: Date(endTime))
                
                descriptionMenuItem.title = String(format: NSLocalizedString("description.enabled_time", comment: "Enabled until %@"), date)
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled", comment: "Disabled")
            }
        }
    }
    
    
    
    func localizedPlural(_ key: String, count: Int, comment: String) -> String {
        let format = NSLocalizedString(key, comment: comment)
        return String(format: format, locale: .current, arguments: [count])
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
    
    

    //MARK: User Interaction

    @IBAction func power(_ sender: Any) {
        if NightShiftManager.isNightShiftEnabled {
            NightShiftManager.respond(to: .userDisabledNightShift)
        } else {
            NightShiftManager.respond(to: .userEnabledNightShift)
        }
    }

    @IBAction func toggleTrueTone(_ sender: NSMenuItem) {
        if CBTrueToneClient.shared.isTrueToneEnabled {
            sender.title = "Turn off True Tone"
        } else {
            sender.title = "Turn on True Tone"
        }
        
        CBTrueToneClient.shared.isTrueToneEnabled = !CBTrueToneClient.shared.isTrueToneEnabled
    }
    
    @IBAction func disableForApp(_ sender: Any) {
        if RuleManager.disabledForApp {
            RuleManager.disabledForApp = false
        } else {
            RuleManager.disabledForApp = true
        }
        Event.disableForCurrentApp(state: (sender as? NSMenuItem)?.state == .on).record()
    }

    @IBAction func disableForDomain(_ sender: Any) {
        if RuleManager.disabledForDomain {
            RuleManager.disabledForDomain = false
        } else {
            RuleManager.disabledForDomain = true
        }
    }

    @IBAction func disableForSubdomain(_ sender: Any) {
        if RuleManager.ruleForSubdomain == .none {
            if RuleManager.disabledForDomain {
                RuleManager.ruleForSubdomain = .enabled
            } else {
                RuleManager.ruleForSubdomain = .disabled
            }
        } else {
            RuleManager.ruleForSubdomain = .none
        }
    }
    
    @IBAction func disableHour(_ sender: Any) {
        if disableHourMenuItem.state == .off {
            let disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                NightShiftManager.nightShiftDisableTimer = .off
                NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            let disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
            
            NightShiftManager.nightShiftDisableTimer = .hour(timer: disableTimer, endDate: disabledUntilDate)
            NightShiftManager.respond(to: .nightShiftDisableTimerStarted)
        } else {
            NightShiftManager.nightShiftDisableTimer = .off
            NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
        }
    }

    @IBAction func disableCustomTime(_ sender: Any) {
        if disableCustomMenuItem.state == .off {
            NSApp.activate(ignoringOtherApps: true)
            
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
            
            customTimeWindow.disableCustomTime = { (timeIntervalInSeconds) in
                let disableTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeIntervalInSeconds),
                                                        repeats: false,
                                                        block: { _ in
                    NightShiftManager.nightShiftDisableTimer = .off
                    NightShiftManager.respond(to: .nightShiftDisableTimerEnded)
                })
                disableTimer.tolerance = 60
                
                let currentDate = Date()
                var addComponents = DateComponents()
                addComponents.second = timeIntervalInSeconds
                let disabledUntilDate = self.calendar.date(byAdding: addComponents, to: currentDate, options: [])!
                
                NightShiftManager.nightShiftDisableTimer = .custom(timer: disableTimer, endDate: disabledUntilDate)
                NightShiftManager.respond(to: .nightShiftDisableTimerStarted)
            }
        } else {
            NightShiftManager.nightShiftDisableTimer = .off
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
        
        NSApp.terminate(self)
    }
}
