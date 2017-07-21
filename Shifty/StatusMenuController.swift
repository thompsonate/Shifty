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
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var disableAppMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView!
    @IBOutlet weak var moonIcon: NSImageView!
    
    var preferencesWindow: PreferencesWindow!
    var currentAppName = ""
    var currentAppBundleId = ""
    var disabledApps = [String]()
    var activeState = true
    
    //Whether or not Night Shift should be toggled based on current app. False if NS is disabled across the board.
    var isShiftForAppEnabled = false
    //True if NS is disabled for app currently owning Menu Bar.
    var isDisabledForApp = false
    
    var isDisableHourSelected = false
    var disableTimer: Timer!
    var disabledUntilDate: Date!
    
    let calendar = NSCalendar(identifier: .gregorian)!
    
    override func awakeFromNib() {
        statusMenu.delegate = self
        preferencesWindow = PreferencesWindow()
        
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
            self.disableDisableTimer()
            self.enableForCurrentApp()
            self.setDescriptionText(keepVisible: true)
        }
        
        isShiftForAppEnabled = BLClient.isNightShiftEnabled
        
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
            if isDisableHourSelected {
                disableDisableTimer()
            }
        } else if sliderView.shiftSlider.floatValue != 0.0 {
            setActiveState(state: BLClient.isNightShiftEnabled)
        }
        
        if disabledApps.contains(currentAppBundleId) {
            disableAppMenuItem.state = NSOnState
            disableAppMenuItem.title = "Disabled for \(currentAppName)"
        } else {
            disableAppMenuItem.state = NSOffState
            disableAppMenuItem.title = "Disable for \(currentAppName)"
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
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
                self.isDisableHourSelected = false
                self.shift(isEnabled: true)
                self.disableHourMenuItem.state = NSOffState
                self.disableHourMenuItem.title = "Disable for an hour"
            }
            disableTimer.tolerance = 60
            
            let currentDate = Date()
            var addComponents = DateComponents()
            addComponents.hour = 1
            disabledUntilDate = calendar.date(byAdding: addComponents, to: currentDate, options: [])!
        } else {
            disableDisableTimer()
            shift(isEnabled: true)
        }
        isShiftForAppEnabled = activeState
    }
    
    func disableDisableTimer() {
        disableTimer?.invalidate()
        isDisableHourSelected = false
        disableHourMenuItem.state = NSOffState
        disableHourMenuItem.title = "Disable for an hour"
    }
    
    @IBAction func disableForApp(_ sender: Any) {
        if disableAppMenuItem.state == NSOffState {
            disabledApps.append(currentAppBundleId)
        } else {
            disabledApps.remove(at: disabledApps.index(of: currentAppBundleId)!)
        }
        updateCurrentApp()
    }
    
    func updateCurrentApp() {
        currentAppName = NSWorkspace.shared().menuBarOwningApplication?.localizedName ?? ""
        currentAppBundleId = NSWorkspace.shared().menuBarOwningApplication?.bundleIdentifier ?? ""
        
        isDisabledForApp = disabledApps.contains(currentAppBundleId)
        
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
        } else {
            disableHourMenuItem.isEnabled = state
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
        if isDisableHourSelected {
            let nowDate = Date()
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = [NSCalendar.Unit.second]
            let disabledTimeLeftComponents = calendar.components([.second], from: nowDate, to: disabledUntilDate, options: [])
            var disabledTimeLeft = Double(disabledTimeLeftComponents.second!) / 60.0
            disabledTimeLeft.round()
            
            if disabledTimeLeft > 1 {
                descriptionMenuItem.title = "Disabled for \(Int(disabledTimeLeft)) more minutes"
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

