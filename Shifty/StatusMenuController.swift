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

let BLClient = CBBlueLightClient()
let SSLocationManager = SunriseSetLocationManager()
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
    @IBOutlet weak var sunIcon: NSImageView!
    @IBOutlet weak var moonIcon: NSImageView!
    
    var preferencesWindow: NSWindowController!
    var prefGeneral: PrefGeneralViewController!
    var prefShortcuts: PrefShortcutsViewController!
    var customTimeWindow: CustomTimeWindow!
    var accessibilityPromptWindow: AccessibilityPromptWindow!
    var currentAppName = ""
    var currentAppBundleId = ""
    var currentDomain = ""
    var currentSubdomain = ""
    var disabledApps = [String]()
    var browserRules = [BrowserRule]()
    var activeState = true
    
    ///Whether or not Night Shift should be toggled based on current app. False if NS is disabled across the board.
    var isShiftForAppEnabled = false
    ///True if Night Shift is disabled for app currently owning Menu Bar.
    var isDisabledForApp = false
    ///True if Night Shift is disabled for browser matching browser rule - domain
    var isDisabledForDomain = false
    ///True if Night Shift is disabled for browser matching browser rule - subdomain
    var isDisabledForSubdomain = false
    ///True if current browser rule is an exception for subdomain (Night Shift is enabled)
    var isExceptionForSubdomain = false
    ///True if change to Night Shift state originated from Shifty
    var shiftOriginatedFromShifty = false
    
    var isDisableHourSelected = false
    var isDisableCustomSelected = false
    var detectScheduledShiftTimer: Timer!
    var disableTimer: Timer!
    var disabledUntilDate: Date!
    
    let calendar = NSCalendar(identifier: .gregorian)!
    
    //MARK: Menu life cycle
        
    override func awakeFromNib() {
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
        
        sunIcon.image?.isTemplate = true
        moonIcon.image?.isTemplate = true
        
        sliderView.shiftSlider.floatValue = BLClient.strength * 100
        
        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
            self.isShiftForAppEnabled = sliderValue != 0.0
        }
        
        sliderView.sliderEnabled = {
            self.shift(isEnabled: true)
            self.disableHourMenuItem.isEnabled = true
            self.disableCustomMenuItem.isEnabled = true
            self.disableAppMenuItem.isEnabled = true
            self.disableDomainMenuItem.isEnabled = true
            self.disableSubdomainMenuItem.isEnabled = true
            self.disableDisableTimer()
            self.enableForCurrentApp()
            self.enableForCurrentDomain()
            self.enableForCurrentSubdomain()
            self.setDescriptionText(keepVisible: true)
        }

        disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
        disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        preferencesMenuItem.title = NSLocalizedString("menu.preferences", comment: "Preferences...")
        quitMenuItem.title = NSLocalizedString("menu.quit", comment: "Quit Shifty")
        
        isShiftForAppEnabled = BLClient.isNightShiftEnabled

        disabledApps = PrefManager.sharedInstance.userDefaults.value(forKey: Keys.disabledApps) as? [String] ?? []
        if let data = PrefManager.sharedInstance.userDefaults.value(forKey: Keys.browserRules) as? Data {
            do {
                browserRules = try PropertyListDecoder().decode(Array<BrowserRule>.self, from: data)
            }
            catch let error {
                NSLog("Error: \(error.localizedDescription)")
                logw("Error: \(error.localizedDescription)")
                browserRules = []
            }
        } else {
            browserRules = []
        }

        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.statusItemClicked = {
            self.power(self)
            self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
            Event.toggleNightShift(state: self.activeState).record()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { _ in
            self.updateCurrentApp()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: nil) { _ in
            self.setToSchedule()
            self.updateDarkMode()
            logw("Screen did wake")
            logw("isShiftForAppEnabled: \(self.isShiftForAppEnabled)")
            logw("schedule: \(BLClient.schedule)")
        }
        
        BLClient.setStatusNotificationBlock(BLNotificationBlock)

        NotificationCenter.default.addObserver(forName: NSNotification.Name("nightShiftToggled"), object: nil, queue: nil) { _ in
            self.blueLightNotification()
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
        
        prefGeneral.updateDarkMode = {
            self.updateDarkMode()
        }
        
        prefShortcuts.bindShortcuts()
        
        SSLocationManager.setup()
        SSLocationManager.updateLocationMonitoringStatus()
        
    }
    
    func menuWillOpen(_: NSMenu) {
        if BLClient.isNightShiftEnabled {
            setActiveState(state: true)
            //disableDisableTimer()

        } else if sliderView.shiftSlider.floatValue != 0.0 {
            setActiveState(state: BLClient.isNightShiftEnabled)
        }
        
        sliderView.shiftSlider.floatValue = BLClient.strength * 100
        setDescriptionText()
        updateCurrentApp()
        
        assignKeyboardShortcutToMenuItem(powerMenuItem, userDefaultsKey: Keys.toggleNightShiftShortcut)
        assignKeyboardShortcutToMenuItem(disableAppMenuItem, userDefaultsKey: Keys.disableAppShortcut)
        assignKeyboardShortcutToMenuItem(disableHourMenuItem, userDefaultsKey: Keys.disableHourShortcut)
        assignKeyboardShortcutToMenuItem(disableCustomMenuItem, userDefaultsKey: Keys.disableCustomShortcut)
        
        Event.menuOpened.record()
        
        //Show accessibility permission prompt on second menu open
        let count = UserDefaults.standard.integer(forKey: Keys.menuLaunchCount)
        UserDefaults.standard.set(count + 1, forKey: Keys.menuLaunchCount)
        if count == 1 && !UIElement.isProcessTrusted(withPrompt: false) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            accessibilityPromptWindow = AccessibilityPromptWindow()
            accessibilityPromptWindow.showWindow(nil)
            logw("Accessibility prompt window shown")
        }
        
        //refresh location if not updated in over a day
        if let data = UserDefaults.standard.value(forKey: Keys.lastKnownLocation) as? Data,
            let location = try? PropertyListDecoder().decode(Location.self, from: data) {
            
            if location.date < Date.init(timeIntervalSinceNow: -86400) {
                SSLocationManager.getLocationFromIP()
            }
        } else {
            SSLocationManager.getLocationFromIP()
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
    
    ///Returns true if the scheduled state is on or if the scheduled shift is close
    var scheduledState: Bool? {
        switch BLClient.schedule {
        case .timedSchedule(let startTime, let endTime):
            let currentTime = Date()
            let isBetweenTimes = currentTime > startTime && currentTime < endTime
            
            //Should be true between startTime and endTime
            return isBetweenTimes
        case .sunSchedule:
            guard let sunTimes = SSLocationManager.sunTimes else { return false }
            let currentTime = Date()            
            let isBetweenTimes = currentTime > sunTimes.sunrise && currentTime < sunTimes.sunset
            
            //Should be false between sunrise and sunset
            return !isBetweenTimes
        default:
            return nil
        }
    }
    
    ///Returns a boolean tuple representing whether or not the current time is close to a scheduled shift and the state of that shift.
    var scheduledShift: (isClose: Bool, shiftState: Bool?) {
        switch BLClient.schedule {
        case .timedSchedule(let startTime, let endTime):
            let currentTime = Date()
            let isCloseToStartTime = abs(currentTime.timeIntervalSince(startTime)) < 5
            let isCloseToEndTime = abs(currentTime.timeIntervalSince(endTime)) < 5
            let isClose = isCloseToStartTime || isCloseToEndTime
            
            let shiftState: Bool?
            if isCloseToStartTime {
                shiftState = true
            } else if isCloseToEndTime {
                shiftState = false
            } else {
                shiftState = nil
            }
            logw("Scheduled shift is close: \(isClose); shift state: \(String(describing: shiftState))")
            return (isClose, shiftState)
        case .sunSchedule:
            guard let sunTimes = SSLocationManager.sunTimes else { return (false, nil) }
            let currentTime = Date()
            let isCloseToSunrise = abs(currentTime.timeIntervalSince(sunTimes.sunrise)) < 600
            let isCloseToSunset = abs(currentTime.timeIntervalSince(sunTimes.sunset)) < 600
            let isClose = isCloseToSunrise || isCloseToSunset
            
            let shiftState: Bool?
            if isCloseToSunset {
                shiftState = true
            } else if isCloseToSunrise {
                shiftState = false
            } else {
                shiftState = nil
            }
            logw("Scheduled shift is close: \(isClose); shift state: \(String(describing: shiftState))")
            return (isClose, shiftState)
        default:
            return (false, nil)
        }
    }
    
    ///Sets Night Shift state based on the set schedule. If a scheduled shift is close, the state is set to what it will be after the shift.
    func setToSchedule() {
        logw("Night Shift set to schedule")
        if !isDisableHourSelected && !isDisableCustomSelected && !isDisabledForApp && !isDisabledForDomain && !isDisabledForSubdomain {
            if scheduledShift.isClose {
                if let shiftState = scheduledShift.shiftState {
                    shift(isEnabled: shiftState)
                }
            } else {
                if let scheduledState = scheduledState {
                    shift(isEnabled: scheduledState)
                }
            }
        } else {
            shift(isEnabled: false)
        }
    }
    
    ///Called when BLNotificationBlock posts a notification
    func blueLightNotification() {
        if !self.shiftOriginatedFromShifty {
            logw("BLNotificationBlock called; state: \(BLClient.isNightShiftEnabled), schedule: \(BLClient.schedule)")
            if isDisabledForApp {
                shift(isEnabled: false)
            } else if isDisableHourSelected || isDisableCustomSelected {
                if scheduledShift.isClose {
                    shift(isEnabled: false)
                } else {
                    isShiftForAppEnabled = BLClient.isNightShiftEnabled
                }
            } else {
                isShiftForAppEnabled = BLClient.isNightShiftEnabled
            }
        }
        shiftOriginatedFromShifty = false
        
        SSLocationManager.updateLocationMonitoringStatus()
        
        if SSLocationManager.shouldShowAlert {
            if SSLocationManager.isAuthorizationDenied && BLClient.isSunSchedule {
                SSLocationManager.showLocationServicesDeniedAlert()
                SSLocationManager.shouldShowAlert = false
            } else if SSLocationManager.isAuthorized && BLClient.isSunSchedule && SSLocationManager.sunTimes == nil {
                SSLocationManager.showLocationErrorAlert()
                SSLocationManager.shouldShowAlert = false
            }
        }
        
        DispatchQueue.main.async {
            self.prefGeneral.updateSchedule?()
        }
        self.updateDarkMode()
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.setMenuBarIcon()
    }
    
    func updateDarkMode() {
        if UserDefaults.standard.bool(forKey: Keys.isDarkModeSyncEnabled) {
            switch BLClient.schedule {
            case .off:
                SLSSetAppearanceThemeLegacy(isShiftForAppEnabled)
                logw("Dark mode set to \(isShiftForAppEnabled)")
            case .sunSchedule:
                if let scheduledState = scheduledState {
                    if scheduledShift.isClose {
                        if let shiftState = scheduledShift.shiftState {
                            SLSSetAppearanceThemeLegacy(shiftState)
                            logw("Dark mode set to \(shiftState)")
                        }
                    } else {
                        SLSSetAppearanceThemeLegacy(scheduledState)
                        logw("Dark mode set to \(scheduledState)")
                    }
                }
            case .timedSchedule(startTime: _, endTime: _):
                if let scheduledState = scheduledState {
                    if scheduledShift.isClose {
                        if let shiftState = scheduledShift.shiftState {
                            SLSSetAppearanceThemeLegacy(shiftState)
                            logw("Dark mode set to \(shiftState)")
                        }
                    } else {
                        SLSSetAppearanceThemeLegacy(scheduledState)
                        logw("Dark mode set to \(scheduledState)")
                    }
                }
            }
        }
    }
    
    
    
    
    
    //MARK: User Interaction
    
    @IBAction func power(_ sender: Any) {
        if sliderView.shiftSlider.floatValue == 0.0 {
            Event.toggleNightShift(state: true).record()
            shift(strength: 50)
        } else {
            Event.toggleNightShift(state: !activeState).record()
            shift(isEnabled: !activeState)
        }
        disableDisableTimer()
        enableForCurrentApp()
        enableForCurrentDomain()
        enableForCurrentSubdomain()
        isShiftForAppEnabled = activeState
        logw("Power menu item clicked; state: \(powerMenuItem.state.rawValue)")
    }
    
    @IBAction func disableForApp(_ sender: Any) {
        if disableAppMenuItem.state == .off {
            disabledApps.append(currentAppBundleId)
        } else {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
        }
        updateCurrentApp()
        PrefManager.sharedInstance.userDefaults.set(disabledApps, forKey: Keys.disabledApps)
        
        Event.disableForCurrentApp(state: (sender as? NSMenuItem)?.state == .on).record()
        logw("Disable for app menu item clicked; state: \(disableAppMenuItem.state.rawValue)")
    }
    
    @IBAction func disableForDomain(_ sender: Any) {
        let rule = BrowserRule(type: .Domain, host: currentDomain, enableNightShift: false)
        if disableDomainMenuItem.state == .off {
            browserRules.append(rule)
        } else {
            browserRules.remove(at: browserRules.index(of: rule)!)
        }
        
        updateCurrentApp()
        PrefManager.sharedInstance.userDefaults.set(try? PropertyListEncoder().encode(browserRules), forKey: Keys.browserRules)
        
        logw("Disable for domain menu item clicked; state: \(disableDomainMenuItem.state.rawValue)")
    }

    @IBAction func disableForSubdomain(_ sender: Any) {
        let rule = BrowserRule(type: .Subdomain, host: currentSubdomain, enableNightShift: isDisabledForDomain)
        if disableSubdomainMenuItem.state == .off {
            browserRules.append(rule)
        } else {
            guard let ruleIndex = browserRules.index(of: rule) else {
                NSLog("Could not find browser rule in array: \(rule)")
                logw("Could not find browser rule in array: \(rule)")
                return
            }
            browserRules.remove(at: ruleIndex)
        }
        updateCurrentApp()
        PrefManager.sharedInstance.userDefaults.set(try? PropertyListEncoder().encode(browserRules), forKey: Keys.browserRules)
        
        logw("Disable for subdomain menu item clicked; state: \(disableSubdomainMenuItem.state.rawValue)")
    }
    
    @IBAction func disableHour(_ sender: Any) {
        if !isDisableHourSelected {
            isDisableHourSelected = true
            shift(isEnabled: false)
            disableHourMenuItem.state = .on
            disableHourMenuItem.title = NSLocalizedString("menu.disabled_hour", comment: "Disabled for an hour")
            disableCustomMenuItem.isEnabled = false
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isDisableHourSelected = false
                self.setToSchedule()
                self.disableHourMenuItem.state = .off
                self.disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
                self.disableCustomMenuItem.isEnabled = true
                self.isShiftForAppEnabled = self.activeState
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
        } else {
            disableDisableTimer()
            setToSchedule()
            setActiveState(state: true)
        }
        isShiftForAppEnabled = activeState
        
        Event.disableForHour(state: isDisableHourSelected).record()
        logw("Disable for hour menu item clicked; state: \(disableHourMenuItem.state.rawValue)")
    }
    
    @IBAction func disableCustomTime(_ sender: Any) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        var timeIntervalInMinutes: Int!
        
        if !isDisableCustomSelected {
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
        } else {
            disableDisableTimer()
            setToSchedule()
            setActiveState(state: true)
        }
        
        customTimeWindow.disableCustomTime = { (timeIntervalInSeconds) in
            self.isDisableCustomSelected = true
            self.shift(isEnabled: false)
            self.disableCustomMenuItem.state = .on
            self.disableCustomMenuItem.title = NSLocalizedString("menu.disabled_custom", comment: "Disabled for custom time")
            self.disableHourMenuItem.isEnabled = false
            
            self.disableTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeIntervalInSeconds), repeats: false) { _ in
                self.isDisableCustomSelected = false
                self.setToSchedule()
                self.disableCustomMenuItem.state = .off
                self.disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
                self.disableHourMenuItem.isEnabled = true
                self.isShiftForAppEnabled = self.activeState
            }
            self.disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.second = timeIntervalInSeconds
            self.disabledUntilDate = self.calendar.date(byAdding: addComponents, to: currentDate, options: [])!
            
            self.isShiftForAppEnabled = self.activeState
            timeIntervalInMinutes = timeIntervalInSeconds * 60
        }
        isShiftForAppEnabled = activeState
        
        Event.disableForCustomTime(state: isDisableCustomSelected, timeInterval: timeIntervalInMinutes).record()
        logw("Disable for custom time menu item clicked; state: \(disableCustomMenuItem.state.rawValue)")
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.preferenceWindowController.showWindow(sender)
        
        Event.preferencesWindowOpened.record()
        logw("Preferences menu item clicked")
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        if isDisableHourSelected || isDisableCustomSelected || isDisabledForApp || isDisabledForDomain || isDisabledForSubdomain {
            shift(isEnabled: true)
        }
        Event.quitShifty.record()
        logw("Quit menu item clicked")
        NSApplication.shared.terminate(self)
    }
    
    
    //MARK: Helper functions
    
    func disableDisableTimer() {
        disableTimer?.invalidate()
        
        if isDisableHourSelected {
            isDisableHourSelected = false
            disableHourMenuItem.state = .off
            disableHourMenuItem.title = NSLocalizedString("menu.disable_hour", comment: "Disable for an hour")
        } else if isDisableCustomSelected {
            isDisableCustomSelected = false
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.title = NSLocalizedString("menu.disable_custom", comment: "Disable for custom time...")
        }
    }
    
    func updateCurrentApp() {
        stopBrowserWatcher()
        currentAppName = NSWorkspace.shared.menuBarOwningApplication?.localizedName ?? ""
        currentAppBundleId = NSWorkspace.shared.menuBarOwningApplication?.bundleIdentifier ?? ""

        isDisabledForApp = disabledApps.contains(currentAppBundleId)
        isDisabledForDomain = false
        isDisabledForSubdomain = false
        isExceptionForSubdomain = false
        
        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            if let supportedBrowser = SupportedBrowser(rawValue: currentAppBundleId) {
                if let pid = NSWorkspace.shared.menuBarOwningApplication?.processIdentifier {
                    do {
                        try startBrowserWatcher(pid) {
                            (self.currentDomain,
                             self.currentSubdomain) = getBrowserCurrentTabDomainSubdomain(browser: supportedBrowser, processIdentifier: pid)
                            (self.isDisabledForDomain,
                            self.isDisabledForSubdomain,
                            self.isExceptionForSubdomain) = checkForBrowserRules(domain: self.currentDomain,
                                                                                 subdomain: self.currentSubdomain,
                                                                                 rules: self.browserRules)
                            self.updateStatus()
                        }
                    } catch let error {
                        NSLog("Error: Could not watch app [\(pid)]: \(error)")
                        logw("Error: Could not watch app [\(pid)]: \(error)")
                    }
                    (currentDomain,
                     currentSubdomain) = getBrowserCurrentTabDomainSubdomain(browser: supportedBrowser, processIdentifier: pid)
                    (isDisabledForDomain,
                     isDisabledForSubdomain,
                     isExceptionForSubdomain) = checkForBrowserRules(domain: self.currentDomain,
                                                                     subdomain: self.currentSubdomain,
                                                                     rules: self.browserRules)
                }
            } else {
                currentDomain = ""
                currentSubdomain = ""
            }
        }
        
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
        }
        
        updateStatus()
    }
    
    func updateStatus() {
        if currentDomain == currentSubdomain || currentSubdomain == "www.\(currentDomain)" {
            currentSubdomain = ""
        }
        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) {
            disableDomainMenuItem.isHidden = currentDomain.isEmpty
            disableSubdomainMenuItem.isHidden = currentSubdomain.isEmpty
        } else {
            disableDomainMenuItem.isHidden = true
            disableSubdomainMenuItem.isHidden = true
        }

        if isDisabledForDomain {
            disableDomainMenuItem.state = .on
            disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_domain", comment: "Disabled for %@"), currentDomain)
        } else {
            disableDomainMenuItem.state = .off
            disableDomainMenuItem.title = String(format: NSLocalizedString("menu.disable_domain", comment: "Disable for %@"), currentDomain)
        }
        if isDisabledForSubdomain {
            if isDisabledForDomain {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enabled_subdomain", comment: "Enabled for %@"), currentSubdomain)
            } else  {
                disableSubdomainMenuItem.state = .on
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disabled_subdomain", comment: "Disabled for %@"), currentSubdomain)
            }
        } else {
            if isDisabledForDomain {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.enable_subdomain", comment: "Enable for %@"), currentSubdomain)
            } else {
                disableSubdomainMenuItem.state = .off
                disableSubdomainMenuItem.title = String(format: NSLocalizedString("menu.disable_subdomain", comment: "Disable for %@"), currentSubdomain)
            }
        }

        if isDisabledForApp {
            disableAppMenuItem.state = .on
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disabled_app", comment: "Disabled for %@"), currentAppName)
        } else {
            disableAppMenuItem.state = .off
            disableAppMenuItem.title = String(format: NSLocalizedString("menu.disable_app", comment: "Disable for %@"), currentAppName)
        }

        if isShiftForAppEnabled && (BLClient.isNightShiftEnabled == isDisabledForApp || BLClient.isNightShiftEnabled == isDisabledForDomain || BLClient.isNightShiftEnabled == isDisabledForSubdomain) {
            shift(isEnabled: !(isDisabledForApp || isDisabledForDomain || isDisabledForSubdomain) || isExceptionForSubdomain )
            setActiveState(state: !(isDisabledForApp || isDisabledForDomain || isDisabledForSubdomain) || isExceptionForSubdomain)
        }
    }
    
    func enableForCurrentApp() {
        if isDisabledForApp {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
            updateCurrentApp()
        }
    }
    
    func enableForCurrentDomain() {
        if isDisabledForDomain {
            let rule = BrowserRule(type: .Domain, host: currentDomain, enableNightShift: false)
            browserRules.remove(at: browserRules.index(of: rule)!)
            updateCurrentApp()
        }
    }
    
    func enableForCurrentSubdomain() {
        if isDisabledForSubdomain {
            let rule = BrowserRule(type: .Subdomain, host: currentSubdomain, enableNightShift: false)
            browserRules.remove(at: browserRules.index(of: rule)!)
            updateCurrentApp()
        }
    }
    
    func setActiveState(state: Bool) {
        self.activeState = state
        self.sliderView.shiftSlider.isEnabled = state
        
        //disableHourMenuItem
        if self.isDisableHourSelected {
            self.disableHourMenuItem.isEnabled = true
        } else if self.customTimeWindow.isWindowLoaded && self.customTimeWindow.window?.isVisible ?? false {
            self.disableHourMenuItem.isEnabled = false
        } else if self.isDisableCustomSelected {
            self.disableHourMenuItem.isEnabled = false
        } else if self.isDisabledForApp {
            self.disableHourMenuItem.isEnabled = true
        } else if self.isDisabledForDomain {
            self.disableHourMenuItem.isEnabled = true
        } else if self.isDisabledForSubdomain {
            self.disableHourMenuItem.isEnabled = true
        } else {
            self.disableHourMenuItem.isEnabled = state
        }
        
        
        //disableCustomMenuItem
        if self.isDisableHourSelected {
            self.disableCustomMenuItem.isEnabled = false
        } else if self.isDisableCustomSelected {
            self.disableCustomMenuItem.isEnabled = true
        } else if self.isDisabledForApp {
            self.disableCustomMenuItem.isEnabled = true
        } else if self.isDisabledForDomain {
            self.disableCustomMenuItem.isEnabled = true
        } else if self.isDisabledForSubdomain {
            self.disableCustomMenuItem.isEnabled = true
        } else {
            self.disableCustomMenuItem.isEnabled = state
        }
        
        //disableAppMenuItem
        if self.isDisableHourSelected {
            self.disableAppMenuItem.isEnabled = true
        } else if self.isDisableCustomSelected {
            self.disableAppMenuItem.isEnabled = true
        } else if self.isDisabledForApp {
            self.disableAppMenuItem.isEnabled = true
        } else if self.isDisabledForDomain {
            self.disableAppMenuItem.isEnabled = true
        } else if self.isDisabledForSubdomain {
            self.disableAppMenuItem.isEnabled = true
        } else {
            self.disableAppMenuItem.isEnabled = state
        }
        
        //disableDomainMenuItem
        if self.isDisableHourSelected {
            self.disableDomainMenuItem.isEnabled = true
        } else if self.isDisableCustomSelected {
            self.disableDomainMenuItem.isEnabled = true
        } else if self.isDisabledForApp {
            self.disableDomainMenuItem.isEnabled = true
        } else if self.isDisabledForDomain {
            self.disableDomainMenuItem.isEnabled = true
        } else if self.isDisabledForSubdomain {
            self.disableDomainMenuItem.isEnabled = true
        } else {
            self.disableDomainMenuItem.isEnabled = state
        }
        
        //disableSubdomainMenuItem
        if self.isDisableHourSelected {
            self.disableSubdomainMenuItem.isEnabled = true
        } else if self.isDisableCustomSelected {
            self.disableSubdomainMenuItem.isEnabled = true
        } else if self.isDisabledForApp {
            self.disableSubdomainMenuItem.isEnabled = true
        } else if self.isDisabledForDomain {
            self.disableSubdomainMenuItem.isEnabled = true
        } else if self.isDisabledForSubdomain {
            self.disableSubdomainMenuItem.isEnabled = true
        } else {
            self.disableSubdomainMenuItem.isEnabled = state
        }
        
        if state {
            self.powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
        } else {
            self.powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            activeState = true
            BLClient.setStrength(strength / 100, commit: true)
            powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
            disableHourMenuItem.isEnabled = true
            disableCustomMenuItem.isEnabled = true
        } else {
            activeState = false
            powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
            disableHourMenuItem.isEnabled = false
            disableCustomMenuItem.isEnabled = false
        }
        if !descriptionMenuItem.isHidden {
            setDescriptionText(keepVisible: true)
        }
        BLClient.setEnabled(strength / 100 != 0.0)
        shiftOriginatedFromShifty = true
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            let sliderValue = sliderView.shiftSlider.floatValue
            BLClient.setStrength(sliderValue / 100, commit: true)
            BLClient.setEnabled(true)
            activeState = true
            powerMenuItem.title = NSLocalizedString("menu.toggle_off", comment: "Turn off Night Shift")
            sliderView.shiftSlider.isEnabled = true
        } else {
            BLClient.setEnabled(false)
            activeState = false
            powerMenuItem.title = NSLocalizedString("menu.toggle_on", comment: "Turn on Night Shift")
        }
        shiftOriginatedFromShifty = true
    }

    func setDescriptionText(keepVisible: Bool = false) {
        if isDisableHourSelected || isDisableCustomSelected {
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
            
            if disabledHoursLeft > 0 || disabledMinutesLeft > 1 {
                if disabledHoursLeft == 0 {
                    descriptionMenuItem.title = String(format: NSLocalizedString("description.disabled_minutes", comment: "Disabled for %d more minutes"), Int(disabledMinutesLeft))
                } else {
                    descriptionMenuItem.title = String(format: NSLocalizedString("description.disabled_hours_minutes", comment: "Disabled for %02d:%02d"), Int(disabledHoursLeft), Int(disabledMinutesLeft))
                }
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled_1_minute", comment: "Disabled for 1 more minute")
            }
            descriptionMenuItem.isHidden = false
            return
        }
        
        switch BLClient.schedule {
        case .off:
            if keepVisible {
                descriptionMenuItem.title = NSLocalizedString("description.enabled", comment: "Enabled")
            } else {
                descriptionMenuItem.isHidden = true
            }
        case .sunSchedule:
            if !keepVisible {
                descriptionMenuItem.isHidden = !activeState
            }
            if activeState {
                descriptionMenuItem.title = NSLocalizedString("description.enabled_sunrise", comment: "Enabled until sunrise")
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled", comment: "Disabled")
            }
        case .timedSchedule(_, let endTime):
            if !keepVisible {
                descriptionMenuItem.isHidden = !activeState
            }
            if activeState {
                let dateFormatter = DateFormatter()
                
                if Bundle.main.preferredLocalizations.first == "zh-Hans" {
                    dateFormatter.dateFormat = "a hh:mm "
                } else {
                    dateFormatter.dateStyle = .none
                    dateFormatter.timeStyle = .short
                }
                
                let date = dateFormatter.string(from: endTime)
                
                descriptionMenuItem.title = String(format: NSLocalizedString("description.enabled_time", comment: "Enabled until %@"), date)
            } else {
                descriptionMenuItem.title = NSLocalizedString("description.disabled", comment: "Disabled")
            }
        }
    }
}

