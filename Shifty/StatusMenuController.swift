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
    @IBOutlet weak var enableBrowserAutomationMenuItem: NSMenuItem!
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
        

        (NSApp.delegate as? AppDelegate)?.statusItemClicked = {
            NightShiftManager.shared.isNightShiftEnabled.toggle()
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
        assignKeyboardShortcutToMenuItem(trueToneMenuItem, userDefaultsKey: Keys.toggleTrueToneShortcut)

        Event.menuOpened.record()
    }
    
    
    
    
    func configureMenuItems() {
        var currentAppName = RuleManager.shared.currentApp?.localizedName ?? ""
        var currentDomain = BrowserManager.shared.currentDomain
        var currentSubdomain = BrowserManager.shared.currentSubdomain
        
        
        // In languages that don't use spaces, we need to add spaces around app name if it's in Latin-script letters.
        // These languages should not include spaces around the "%@" in its Localizable.strings file.
        if Bundle.main.preferredLocalizations.first == "zh-Hans" {
            var normalizedName = currentAppName as NSString
            if normalizedName.length > 0 {
                let startingCharacter = normalizedName.character(at: 0)
                let endingCharacter = normalizedName.character(at: normalizedName.length - 1)
                if 0x4E00 > startingCharacter || startingCharacter > 0x9FA5 {
                    normalizedName = " \(normalizedName)" as NSString
                }
                if 0x4E00 > endingCharacter || endingCharacter > 0x9FA5 {
                    normalizedName = "\(normalizedName) " as NSString
                }
                currentAppName = normalizedName as String
            }
            
            currentDomain = " \(currentDomain ?? "") "
            currentSubdomain = " \(currentSubdomain ?? "") "
        }
        
        sliderView.shiftSlider.floatValue = NightShiftManager.shared.colorTemperature * 100
        
        
        // MARK: toggle Night Shift
        if NightShiftManager.shared.isNightShiftEnabled {
            powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
            sliderView.shiftSlider.isEnabled = true
        } else {
            powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
            sliderView.shiftSlider.isEnabled = false
        }
        
        
        //MARK: disable for app
        if RuleManager.shared.disabledForApp {
            disableAppMenuItem.state = .on
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), currentAppName)
        } else {
            disableAppMenuItem.state = .off
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), currentAppName)
        }
        
        
        // MARK: disable for domain
        if BrowserManager.shared.hasValidDomain {
            disableDomainMenuItem.isHidden = false
            if RuleManager.shared.disabledForDomain {
                disableDomainMenuItem.state = .on
                disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), currentDomain ?? "")
            } else {
                disableDomainMenuItem.state = .off
                disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), currentDomain ?? "")
            }
        } else {
            disableDomainMenuItem.isHidden = true
        }
        
        
        // MARK: disable for subdomain
        if BrowserManager.shared.hasValidSubdomain {
            disableSubdomainMenuItem.isHidden = false
            if RuleManager.shared.ruleForSubdomain == .enabled {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enabled_for", comment: "Enabled for %@"), currentSubdomain ?? "")
            } else if RuleManager.shared.ruleForSubdomain == .disabled {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_for", comment: "Disabled for %@"), currentSubdomain ?? "")
            } else if RuleManager.shared.disabledForDomain {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enable_for", comment: "Enable for %@"), currentSubdomain ?? "")
            } else {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disable_for", comment: "Disable for %@"), currentSubdomain ?? "")
            }
        } else {
            disableSubdomainMenuItem.isHidden = true
        }
        
        
        // MARK: enable browser automation
        if BrowserManager.shared.currentAppIsSupportedBrowser &&
            BrowserManager.shared.permissionToAutomateCurrentApp == .denied {
            
            enableBrowserAutomationMenuItem.isHidden = false
            enableBrowserAutomationMenuItem.title = String(format: NSLocalizedString("menu.allow_browser_automation",
                                                                                     comment: "Allow Website Shifting with Browser"), currentAppName)
        } else {
            enableBrowserAutomationMenuItem.isHidden = true
        }
        
        
        // MARK: disable timer
        switch NightShiftManager.shared.nightShiftDisableTimerState {
        case .off:
            disableHourMenuItem.state = .off
            disableHourMenuItem.isEnabled = true
            disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
            
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.isEnabled = true
            disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        case .hour:
            disableHourMenuItem.state = .on
            disableHourMenuItem.isEnabled = true
            disableHourMenuItem.title = NSLocalizedString("menu.disabled_hour", comment: "Disabled for an hour")
            
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.isEnabled = false
            disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        case .custom:
            disableHourMenuItem.state = .off
            disableHourMenuItem.isEnabled = false
            disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
            
            disableCustomMenuItem.state = .on
            disableCustomMenuItem.isEnabled = true
            disableCustomMenuItem.title = NSLocalizedString("menu.disabled_custom", comment: "Disabled for custom time")
        }
        
        
        // MARK: toggle True Tone
        if #available(macOS 10.14, *) {
            trueToneMenuItem.isHidden = false
            trueToneMenuItem.isEnabled = true
            
            switch CBTrueToneClient.shared.state {
            case .unsupported:
                trueToneMenuItem.isHidden = true
            case .unavailable:
                trueToneMenuItem.isEnabled = false
                trueToneMenuItem.title = NSLocalizedString("menu.true_tone_unavailable", comment: "True Tone is not available")
            case .enabled:
                trueToneMenuItem.title = NSLocalizedString("menu.true_tone_off", comment: "Turn off True Tone")
            case .disabled:
                if NightShiftManager.shared.isDisableRuleActive {
                    trueToneMenuItem.isEnabled = false
                    if RuleManager.shared.disabledForDomain {
                        trueToneMenuItem.title = String(format: NSLocalizedString("menu.true_tone_disabled_for", comment: "True Tone is disabled for %@"), currentDomain ?? "")
                    } else if RuleManager.shared.ruleForSubdomain == .disabled {
                        trueToneMenuItem.title = String(format: NSLocalizedString("menu.true_tone_disabled_for", comment: "True Tone is disabled for %@"), currentSubdomain ?? "")
                    } else {
                        trueToneMenuItem.title = String(format: NSLocalizedString("menu.true_tone_disabled_for", comment: "True Tone is disabled for %@"), currentAppName)
                    }
                } else {
                    trueToneMenuItem.title = NSLocalizedString("menu.true_tone_on", comment: "Turn on True Tone")
                }
            }
        } else {
            trueToneMenuItem.isHidden = true
        }
    }
    
    
    
    
    func setDescriptionText(keepVisible: Bool = false) {
        if NightShiftManager.shared.isDisabledWithTimer {
            var disabledUntilDate: Date
            
            switch NightShiftManager.shared.nightShiftDisableTimerState {
            case .hour(endDate: let date), .custom(endDate: let date):
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
        
        switch NightShiftManager.shared.schedule {
        case .off:
            if keepVisible {
                descriptionMenuItem.title = NSLocalizedString("description.enabled", comment: "Enabled")
            } else {
                descriptionMenuItem.isHidden = true
            }
        case .solar:
            if !keepVisible {
                descriptionMenuItem.isHidden = !NightShiftManager.shared.isNightShiftEnabled
            }
            if NightShiftManager.shared.isNightShiftEnabled {
                descriptionMenuItem.title = NSLocalizedString("description.enabled_sunrise", comment: "Enabled until sunrise")
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled", comment: "Disabled")
            }
        case .custom(_, let endTime):
            if !keepVisible {
                descriptionMenuItem.isHidden = !NightShiftManager.shared.isNightShiftEnabled
            }
            if NightShiftManager.shared.isNightShiftEnabled {
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
            let flags = shortcut.modifierFlags
            menuItem.keyEquivalentModifierMask = flags
            menuItem.keyEquivalent = shortcut.keyCodeString.lowercased()
        } else {
            menuItem.keyEquivalentModifierMask = []
            menuItem.keyEquivalent = ""
        }
    }
    
    

    // MARK: User Interaction

    @IBAction func power(_ sender: Any) {
        NightShiftManager.shared.isNightShiftEnabled.toggle()
    }
    
    
    
    @IBAction func disableForApp(_ sender: Any) {
        if RuleManager.shared.disabledForApp {
            RuleManager.shared.disabledForApp = false
        } else {
            RuleManager.shared.disabledForApp = true
        }
        Event.disableForCurrentApp(state: (sender as? NSMenuItem)?.state == .on).record()
    }
    
    

    @IBAction func disableForDomain(_ sender: Any) {
        if RuleManager.shared.disabledForDomain {
            RuleManager.shared.disabledForDomain = false
        } else {
            RuleManager.shared.disabledForDomain = true
        }
    }
    
    

    @IBAction func disableForSubdomain(_ sender: Any) {
        if RuleManager.shared.ruleForSubdomain == .none {
            if RuleManager.shared.disabledForDomain {
                RuleManager.shared.ruleForSubdomain = .enabled
            } else {
                RuleManager.shared.ruleForSubdomain = .disabled
            }
        } else {
            RuleManager.shared.ruleForSubdomain = .none
        }
    }
    
    
    
    @IBAction func enableBrowserAutomation(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }
    
    
    
    @IBAction func disableHour(_ sender: Any) {
        if disableHourMenuItem.state == .off {
            NightShiftManager.shared.setDisableTimer(forTimeInterval: 3600)
        } else {
            NightShiftManager.shared.invalidateDisableTimer()
        }
    }
    
    

    @IBAction func disableCustomTime(_ sender: Any) {
        if disableCustomMenuItem.state == .off {
            NSApp.activate(ignoringOtherApps: true)
            
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
            
            customTimeWindow.disableCustomTime = { seconds in
                NightShiftManager.shared.setDisableTimer(forTimeInterval: TimeInterval(seconds))
            }
        } else {
            NightShiftManager.shared.invalidateDisableTimer()
        }
    }
    
    
    
    @IBAction func toggleTrueTone(_ sender: Any) {
        if #available(macOS 10.14, *) {
            CBTrueToneClient.shared.isTrueToneEnabled = !CBTrueToneClient.shared.isTrueToneEnabled
        }
    }
    
    

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        (NSApp.delegate as? AppDelegate)?.preferenceWindowController.showWindow(sender)

        Event.preferencesWindowOpened.record()
    }
    
    

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NightShiftManager.shared.respond(to: .nightShiftDisableTimerEnded)
        NightShiftManager.shared.respond(to: .nightShiftDisableRuleDeactivated)

        Event.quitShifty.record()
        NotificationCenter.default.post(name: .terminateApp, object: self)
        
        NSApp.terminate(self)
    }
}
