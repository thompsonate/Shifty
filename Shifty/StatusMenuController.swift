//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

let BLClient = CBBlueLightClient()

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
    
    var preferencesWindow: PreferencesWindow!
    var aboutWindow: AboutWindow!
    var customTimeWindow: CustomTimeWindow!
    var currentAppName = ""
    var currentAppBundleId = ""
    var disabledApps = [String]()
    var activeState = true
    
    ///Whether or not Night Shift is currently enabled
    var shouldNightShiftBeEnabled = false
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
        aboutWindow = AboutWindow()
        preferencesWindow = PreferencesWindow()
        customTimeWindow = CustomTimeWindow()
        
        descriptionMenuItem.isEnabled = false
        sliderMenuItem.view = sliderView
        
        sunIcon.image?.isTemplate = true
        moonIcon.image?.isTemplate = true
        
        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
            self.shouldNightShiftBeEnabled = sliderValue != 0.0
        }
        
        sliderView.sliderEnabled = {
            self.shift(isEnabled: true)
            self.disableHourMenuItem.isEnabled = true
            self.disableCustomMenuItem.isEnabled = true
            self.disableDisableTimer()
            self.enableForCurrentApp()
            self.setDescriptionText(keepVisible: true)
        }
        
        shouldNightShiftBeEnabled = BLClient.isNightShiftEnabled
        disabledApps = PreferencesManager.sharedInstance.userDefaults.value(forKey: Keys.disabledApps) as? [String] ?? []
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.statusItemClicked = {
            self.power(self)
            self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
            Event.toggleNightShift(state: self.activeState).record()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { notification in
            self.updateCurrentApp()
        }
        
        BLClient.setStatusNotificationBlock(BLNotificationBlock)

        NotificationCenter.default.addObserver(forName: NSNotification.Name.init(rawValue: "nightShiftToggled"), object: nil, queue: nil) { _ in
            if !self.shiftOriginatedFromShifty {
                if self.isDisabledForApp {
                    self.shift(isEnabled: false)
                    self.shouldNightShiftBeEnabled = true
                } else if self.shouldNightShiftBeEnabled == BLClient.isNightShiftEnabled {
                    self.setActiveState(state: BLClient.isNightShiftEnabled)
                    self.updateCurrentApp()
                    self.shouldNightShiftBeEnabled = BLClient.isNightShiftEnabled
                } else {
                    self.shouldNightShiftBeEnabled = BLClient.isNightShiftEnabled
                }
            }
            self.shiftOriginatedFromShifty = false
        }
    }
    
    func menuWillOpen(_: NSMenu) {
        if BLClient.isNightShiftEnabled {
            sliderView.shiftSlider.floatValue = BLClient.strength * 100
            setActiveState(state: true)
            disableDisableTimer()

        } else if sliderView.shiftSlider.floatValue != 0.0 {
            setActiveState(state: BLClient.isNightShiftEnabled)
        }
        
        setDescriptionText()
        updateCurrentApp()
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
        shouldNightShiftBeEnabled = activeState
    }
    
    @IBAction func disableHour(_ sender: NSMenuItem) {
        if !isDisableHourSelected {
            isDisableHourSelected = true
            shift(isEnabled: false)
            disableHourMenuItem.state = .on
            disableHourMenuItem.title = "Disabled for an hour"
            disableCustomMenuItem.isEnabled = false
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isDisableHourSelected = false
                self.shift(isEnabled: true)
                self.disableHourMenuItem.state = .off
                self.disableHourMenuItem.title = "Disable for an hour"
                self.disableCustomMenuItem.isEnabled = true
                self.shouldNightShiftBeEnabled = self.activeState
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
        } else {
            shift(isEnabled: true)
            disableDisableTimer()
            disableCustomMenuItem.isEnabled = true
            shouldNightShiftBeEnabled = activeState
        }
        shouldNightShiftBeEnabled = activeState
        Event.disableForHour(state: isDisableHourSelected).record()
    }
    
    @IBAction func disableCustomTime(_ sender: NSMenuItem) {
        var timeIntervalInMinutes: Int!
        
        if !isDisableCustomSelected {
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
        } else {
            shift(isEnabled: true)
            disableDisableTimer()
            disableCustomMenuItem.isEnabled = true
            shouldNightShiftBeEnabled = activeState
        }
        
        customTimeWindow.disableCustomTime = { (timeIntervalInSeconds) in
            self.isDisableCustomSelected = true
            self.shift(isEnabled: false)
            self.disableCustomMenuItem.state = .on
            self.disableCustomMenuItem.title = "Disabled for custom time"
            self.disableHourMenuItem.isEnabled = false
            
            self.disableTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeIntervalInSeconds), repeats: false) { _ in
                self.isDisableCustomSelected = false
                self.shift(isEnabled: true)
                self.disableCustomMenuItem.state = .off
                self.disableCustomMenuItem.title = "Disable for custom time..."
                self.disableHourMenuItem.isEnabled = true
                self.shouldNightShiftBeEnabled = self.activeState
            }
            self.disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.second = timeIntervalInSeconds
            self.disabledUntilDate = self.calendar.date(byAdding: addComponents, to: currentDate, options: [])!
            
            self.shouldNightShiftBeEnabled = self.activeState
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
    
    @IBAction func disableForApp(_ sender: NSMenuItem) {
        if disableAppMenuItem.state == .off {
            disabledApps.append(currentAppBundleId)
        } else {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
        }
        updateCurrentApp()
        PreferencesManager.sharedInstance.userDefaults.set(disabledApps, forKey: Keys.disabledApps)
        Event.disableForCurrentApp(state: sender.state == .on).record()
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
            
        if shouldNightShiftBeEnabled && BLClient.isNightShiftEnabled == isDisabledForApp {
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
        activeState = state
        sliderView.shiftSlider.isEnabled = state
        
        if isDisableHourSelected {
            disableHourMenuItem.isEnabled = true
        } else if customTimeWindow.isWindowLoaded && customTimeWindow.window?.isVisible ?? false {
            disableHourMenuItem.isEnabled = false
        } else if isDisabledForApp {
            disableHourMenuItem.isEnabled = false
        } else {
            disableHourMenuItem.isEnabled = state
        }
        
        if isDisableCustomSelected {
            disableCustomMenuItem.isEnabled = true
        } else if isDisabledForApp {
            disableCustomMenuItem.isEnabled = false
        } else {
            disableCustomMenuItem.isEnabled = state
        }
        
        if state {
            powerMenuItem.title = "Turn off Night Shift"
        } else {
            powerMenuItem.title = "Turn on Night Shift"
        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            activeState = true
            BLClient.setStrength(strength/100, commit: true)
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
        BLClient.setEnabled(strength/100 != 0.0)
        shiftOriginatedFromShifty = true
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            let sliderValue = sliderView.shiftSlider.floatValue
            BLClient.setStrength(sliderValue/100, commit: true)
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
            dateComponentsFormatter.allowedUnits = [NSCalendar.Unit.second]
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
    
    @IBAction func aboutClicked(_ sender: NSMenuItem) {
        aboutWindow.showWindow(nil)
        aboutWindow.window?.orderFrontRegardless()
        Event.aboutWindowOpened.record()
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
        preferencesWindow.window?.orderFrontRegardless()
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

