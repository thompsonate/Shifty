//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import MASShortcut

let BLClient = CBBlueLightClient()
let SSLocationManager = SunriseSetLocationManager()

class StatusMenuController: NSObject, NSMenuDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var sliderMenuItem: NSMenuItem!
    @IBOutlet weak var descriptionMenuItem: NSMenuItem!
    @IBOutlet weak var disableAppMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var disableCustomMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView!
    @IBOutlet weak var moonIcon: NSImageView!
    
    var preferencesWindow: NSWindowController!
    var prefGeneral: PrefGeneralViewController!
    var prefShortcuts: PrefShortcutsViewController!
    var customTimeWindow: CustomTimeWindow!
    var currentAppName = ""
    var currentAppBundleId = ""
    var disabledApps = [String]()
    var activeState = true
    
    ///Whether or not Night Shift should be toggled based on current app. False if NS is disabled across the board.
    var isShiftForAppEnabled = false
    ///True if Night Shift is disabled for app currently owning Menu Bar.
    var isDisabledForApp = false
    ///True if change to Night Shift state originated from Shifty
    var shiftOriginatedFromShifty = false
    
    var isDisableHourSelected = false
    var isDisableCustomSelected = false
    var detectScheduledShiftTimer: Timer!
    var disableTimer: Timer!
    var disabledUntilDate: Date!
    
    let calendar = NSCalendar(identifier: .gregorian)!
        
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
        
        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
            self.isShiftForAppEnabled = sliderValue != 0.0
        }
        
        sliderView.sliderEnabled = {
            self.shift(isEnabled: true)
            self.disableHourMenuItem.isEnabled = true
            self.disableCustomMenuItem.isEnabled = true
            self.disableDisableTimer()
            self.enableForCurrentApp()
            self.setDescriptionText(keepVisible: true)
        }
        
        isShiftForAppEnabled = BLClient.isNightShiftEnabled

        disabledApps = PrefManager.sharedInstance.userDefaults.value(forKey: Keys.disabledApps) as? [String] ?? []
        
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
        }
        
        BLClient.setStatusNotificationBlock(BLNotificationBlock)

        NotificationCenter.default.addObserver(forName: NSNotification.Name("nightShiftToggled"), object: nil, queue: nil) { _ in
            self.blueLightNotification()
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
            return (isClose, shiftState)
        default:
            return (false, nil)
        }
    }
    
    ///Sets Night Shift state based on the set schedule. If a scheduled shift is close, the state is set to what it will be after the shift.
    func setToSchedule() {
        if !isDisableHourSelected && !isDisableCustomSelected && !isDisabledForApp {
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
            case .sunSchedule:
                if let scheduledState = scheduledState {
                    if scheduledShift.isClose {
                        if let shiftState = scheduledShift.shiftState {
                            SLSSetAppearanceThemeLegacy(shiftState)
                        }
                    } else {
                        SLSSetAppearanceThemeLegacy(scheduledState)
                    }
                }
            case .timedSchedule(startTime: _, endTime: _):
                if let scheduledState = scheduledState {
                    if scheduledShift.isClose {
                        if let shiftState = scheduledShift.shiftState {
                            SLSSetAppearanceThemeLegacy(shiftState)
                        }
                    } else {
                        SLSSetAppearanceThemeLegacy(scheduledState)
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
        isShiftForAppEnabled = activeState
    }
    
    @IBAction func disableHour(_ sender: Any) {
        if !isDisableHourSelected {
            isDisableHourSelected = true
            shift(isEnabled: false)
            disableHourMenuItem.state = .on
            disableHourMenuItem.title = "Disabled for an hour"
            disableCustomMenuItem.isEnabled = false
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isDisableHourSelected = false
                self.setToSchedule()
                self.disableHourMenuItem.state = .off
                self.disableHourMenuItem.title = "Disable for an hour"
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
            self.disableCustomMenuItem.title = "Disabled for custom time"
            self.disableHourMenuItem.isEnabled = false
            
            self.disableTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeIntervalInSeconds), repeats: false) { _ in
                self.isDisableCustomSelected = false
                self.setToSchedule()
                self.disableCustomMenuItem.state = .off
                self.disableCustomMenuItem.title = "Disable for custom time..."
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
        
        Event.disableForCustomTime(state: isDisableCustomSelected, timeInterval: timeIntervalInMinutes).record()
    }
    
    func disableDisableTimer() {
        disableTimer?.invalidate()
        
        if isDisableHourSelected {
            isDisableHourSelected = false
            disableHourMenuItem.state = .off
            disableHourMenuItem.title = "Disable for an hour"
        } else if isDisableCustomSelected {
            isDisableCustomSelected = false
            disableCustomMenuItem.state = .off
            disableCustomMenuItem.title = "Disable for custom time..."
        }
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
    }
    
    
    func updateCurrentApp() {
        currentAppName = NSWorkspace.shared.menuBarOwningApplication?.localizedName ?? ""
        currentAppBundleId = NSWorkspace.shared.menuBarOwningApplication?.bundleIdentifier ?? ""

        isDisabledForApp = disabledApps.contains(currentAppBundleId)
        
        if isDisabledForApp {
            disableAppMenuItem.state = .on
            disableAppMenuItem.title = "Disabled for \(currentAppName)"
        } else {
            disableAppMenuItem.state = .off
            disableAppMenuItem.title = "Disable for \(currentAppName)"
        }
        
        if isShiftForAppEnabled && BLClient.isNightShiftEnabled == isDisabledForApp {
            shift(isEnabled: !isDisabledForApp)
            setActiveState(state: !isDisabledForApp)
        }
    }
    
    func enableForCurrentApp() {
        if isDisabledForApp {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
            updateCurrentApp()
        }
    }
    
    func setActiveState(state: Bool) {
        self.activeState = state
        self.sliderView.shiftSlider.isEnabled = state
        
        if self.isDisableHourSelected {
            self.disableHourMenuItem.isEnabled = true
        } else if self.customTimeWindow.isWindowLoaded && self.customTimeWindow.window?.isVisible ?? false {
            self.disableHourMenuItem.isEnabled = false
        } else if self.isDisabledForApp {
            self.disableHourMenuItem.isEnabled = false
        } else {
            self.disableHourMenuItem.isEnabled = state
        }
        
        if self.isDisableCustomSelected {
            self.disableCustomMenuItem.isEnabled = true
        } else if self.isDisabledForApp {
            self.disableCustomMenuItem.isEnabled = false
        } else {
            self.disableCustomMenuItem.isEnabled = state
        }
        
        if state {
            self.powerMenuItem.title = "Turn off Night Shift"
        } else {
            self.powerMenuItem.title = "Turn on Night Shift"
        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            activeState = true
            BLClient.setStrength(strength / 100, commit: true)
            powerMenuItem.title = "Turn off Night Shift"
            disableHourMenuItem.isEnabled = true
            disableCustomMenuItem.isEnabled = true
        } else {
            activeState = false
            powerMenuItem.title = "Turn on Night Shift"
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
            powerMenuItem.title = "Turn off Night Shift"
            sliderView.shiftSlider.isEnabled = true
        } else {
            BLClient.setEnabled(false)
            activeState = false
            powerMenuItem.title = "Turn on Night Shift"
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
                    descriptionMenuItem.title = "Disabled for \(Int(disabledMinutesLeft)) more minutes"
                } else {
                    let formattedHoursLeft = String(format: "%02d", Int(disabledHoursLeft))
                    let formattedMinutesLeft = String(format: "%02d", Int(disabledMinutesLeft))
                    descriptionMenuItem.title = "Disabled for \(formattedHoursLeft)h \(formattedMinutesLeft)m"
                }
            } else {
                descriptionMenuItem.title = "Disabled for 1 more minute"
            }
            descriptionMenuItem.isHidden = false
            return
        }
        
        switch BLClient.schedule {
        case .off:
            if keepVisible {
                descriptionMenuItem.title = "Enabled"
            } else {
                descriptionMenuItem.isHidden = true
            }
        case .sunSchedule:
            if !keepVisible {
                descriptionMenuItem.isHidden = !activeState
            }
            if activeState {
                descriptionMenuItem.title = "Enabled until sunrise"
            } else {
                descriptionMenuItem.title = "Disabled"
            }
        case .timedSchedule(_, let endTime):
            if !keepVisible {
                descriptionMenuItem.isHidden = !activeState
            }
            if activeState {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                let date = dateFormatter.string(from: endTime)
                
                descriptionMenuItem.title = "Enabled until \(date)"
            } else {
                descriptionMenuItem.title = "Disabled"
            }
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.preferenceWindowController.showWindow(sender)
        
        Event.preferencesWindowOpened.record()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        if isDisableHourSelected || isDisableCustomSelected || isDisabledForApp {
            shift(isEnabled: true)
        }
        Event.quitShifty.record()
        NSApplication.shared.terminate(self)
    }
}

