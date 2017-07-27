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
    
    ///Whether or not Night Shift should be toggled based on current app. False if NS is disabled across the board.
    var isShiftForAppEnabled = false
    ///True if NS is disabled for app currently owning Menu Bar.
    var isDisabledForApp = false
    
    var isDisableHourSelected = false
    var isDisableCustomSelected = false
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
            self.isShiftForAppEnabled = sliderValue != 0.0
        }
        
        sliderView.sliderEnabled = { _ in
            self.shift(isEnabled: true)
            self.disableHourMenuItem.isEnabled = true
            self.disableCustomMenuItem.isEnabled = true
            self.disableDisableTimer()
            self.enableForCurrentApp()
            self.setDescriptionText(keepVisible: true)
        }
        
        isShiftForAppEnabled = BLClient.isNightShiftEnabled
        disabledApps = PreferencesManager.sharedInstance.userDefaults.value(forKey: Keys.disabledApps) as? [String] ?? []
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.statusItemClicked = { _ in
            self.power(self)
            self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
        }
        
        NSWorkspace.shared().notificationCenter.addObserver(forName: .NSWorkspaceDidActivateApplication, object: nil, queue: nil) { notification in
            self.updateCurrentApp()
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
            shift(strength: 50)
        } else {
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
            disableHourMenuItem.state = NSOnState
            disableHourMenuItem.title = "Disabled for an hour"
            disableCustomMenuItem.isEnabled = false
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isDisableHourSelected = false
                self.shift(isEnabled: true)
                self.disableHourMenuItem.state = NSOffState
                self.disableHourMenuItem.title = "Disable for an hour"
                self.disableCustomMenuItem.isEnabled = true
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
        } else {
            disableDisableTimer()
            shift(isEnabled: true)
            disableCustomMenuItem.isEnabled = true
        }
        isShiftForAppEnabled = activeState
    }
    
    @IBAction func disableCustomTime(_ sender: NSMenuItem) {
        if !isDisableCustomSelected {
            customTimeWindow.showWindow(nil)
            customTimeWindow.window?.orderFrontRegardless()
        }
        
        customTimeWindow.disableCustomTime = { (timeIntervalInSeconds) in
            self.isDisableCustomSelected = true
            self.shift(isEnabled: false)
            self.disableCustomMenuItem.state = NSOnState
            self.disableCustomMenuItem.title = "Disabled for custom time"
            self.disableHourMenuItem.isEnabled = false
            
            self.disableTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeIntervalInSeconds), repeats: false) { _ in
                self.isDisableCustomSelected = false
                self.shift(isEnabled: true)
                self.disableCustomMenuItem.state = NSOffState
                self.disableCustomMenuItem.title = "Disable for custom time..."
                self.disableHourMenuItem.isEnabled = true
            }
            self.disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.second = timeIntervalInSeconds
            self.disabledUntilDate = self.calendar.date(byAdding: addComponents, to: currentDate, options: [])!
            
            self.isShiftForAppEnabled = self.activeState
        }
        
        if isDisableCustomSelected {
            disableDisableTimer()
            shift(isEnabled: true)
            disableCustomMenuItem.isEnabled = true
            isShiftForAppEnabled = activeState
        }
    }
    
    func disableDisableTimer() {
        disableTimer?.invalidate()
        
        if isDisableHourSelected {
            isDisableHourSelected = false
            disableHourMenuItem.state = NSOffState
            disableHourMenuItem.title = "Disable for an hour"
        } else if isDisableCustomSelected {
            isDisableCustomSelected = false
            disableCustomMenuItem.state = NSOffState
            disableCustomMenuItem.title = "Disable for custom time..."
        }
    }
    
    @IBAction func disableForApp(_ sender: Any) {
        if disableAppMenuItem.state == NSOffState {
            disabledApps.append(currentAppBundleId)
        } else {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
        }
        updateCurrentApp()
        PreferencesManager.sharedInstance.userDefaults.set(disabledApps, forKey: Keys.disabledApps)
    }
    
    func updateCurrentApp() {
        currentAppName = NSWorkspace.shared().menuBarOwningApplication?.localizedName ?? ""
        currentAppBundleId = NSWorkspace.shared().menuBarOwningApplication?.bundleIdentifier ?? ""
        
        isDisabledForApp = disabledApps.contains(currentAppBundleId)
        
        if disabledApps.contains(currentAppBundleId) {
            disableAppMenuItem.state = NSOnState
            disableAppMenuItem.title = "Disabled for \(currentAppName)"
        } else {
            disableAppMenuItem.state = NSOffState
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
        activeState = state
        sliderView.shiftSlider.isEnabled = state
        
        if isDisableHourSelected || isDisabledForApp {
            disableHourMenuItem.isEnabled = true
        } else if customTimeWindow.isWindowLoaded && customTimeWindow.window?.isVisible ?? false {
            disableHourMenuItem.isEnabled = false
        } else {
            disableHourMenuItem.isEnabled = state
        }
        
        if isDisableCustomSelected || isDisabledForApp {
            disableCustomMenuItem.isEnabled = true
        } else {
            disableCustomMenuItem.isEnabled = state
        }
        
        if state {
            powerMenuItem.title = "Turn Off Night Shift"
        } else {
            powerMenuItem.title = "Turn On Night Shift"
        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            activeState = true
            BLClient.setStrength(strength/100, commit: true)
            powerMenuItem.title = "Turn Off Night Shift"
            disableHourMenuItem.isEnabled = true
        } else {
            activeState = false
            powerMenuItem.title = "Turn On Night Shift"
            disableHourMenuItem.isEnabled = false
        }
        if !descriptionMenuItem.isHidden {
            setDescriptionText(keepVisible: true)
        }
        BLClient.setEnabled(strength/100 != 0.0)
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            let sliderValue = sliderView.shiftSlider.floatValue
            BLClient.setStrength(sliderValue/100, commit: true)
            BLClient.setEnabled(true)
            activeState = true
            powerMenuItem.title = "Turn Off Night Shift"
            sliderView.shiftSlider.isEnabled = true
            
        } else {
            BLClient.setEnabled(false)
            activeState = false
            powerMenuItem.title = "Turn On Night Shift"
        }
    }
    
    func setDescriptionText(keepVisible: Bool = false) {
        if isDisableHourSelected || isDisableCustomSelected {
            let nowDate = Date()
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = [NSCalendar.Unit.second]
            let disabledTimeLeftComponents = calendar.components([.second], from: nowDate, to: disabledUntilDate, options: [])
            let disabledHoursLeft = disabledTimeLeftComponents.second! / 3600
            let disabledMinutesLeft = disabledTimeLeftComponents.second! / 60 % 60
            
            if disabledMinutesLeft > 1 {
                if disabledHoursLeft == 0 {
                    descriptionMenuItem.title = "Disabled for \(Int(disabledMinutesLeft)) more minutes"
                } else {
                    descriptionMenuItem.title = "Disabled for \(Int(disabledHoursLeft))h \(Int(disabledMinutesLeft))m"
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
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
        preferencesWindow.window?.orderFrontRegardless()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        if isDisableHourSelected {
            shift(isEnabled: true)
        }
        NSApplication.shared().terminate(self)
    }
}

