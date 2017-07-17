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
    @IBOutlet weak var descriptionText: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView!
    @IBOutlet weak var moonIcon: NSImageView!
    
    var preferencesWindow: PreferencesWindow!
    var descriptionMenuItem: NSMenuItem!
    var sliderMenuItem: NSMenuItem!
    var activeState = true
    var isDisableSelected = false
    var disableTimer: Timer!
    var disabledUntilDate: Date!
    
    let calendar = NSCalendar(identifier: .gregorian)!
    
    override func awakeFromNib() {
        statusMenu.delegate = self
        preferencesWindow = PreferencesWindow()
        
        descriptionMenuItem = statusMenu.item(withTitle: "Description")
        descriptionMenuItem.isEnabled = false
        
        sliderMenuItem = statusMenu.item(withTitle: "Slider")
        sliderMenuItem.view = sliderView
        
        sunIcon.image?.isTemplate = true
        moonIcon.image?.isTemplate = true

        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
        }
        
        sliderView.sliderEnabled = { _ in
            self.shift(isEnabled: true)
            self.disableHourMenuItem.isEnabled = true
            self.disableDisableTimer()
            self.setDescriptionText(keepVisible: true)
        }
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.statusItemClicked = { _ in
            self.power(self)
            
        self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
        }
    }
    
    func menuWillOpen(_: NSMenu) {
        if BLClient.isNightShiftEnabled {
            sliderView.shiftSlider.floatValue = BLClient.strength * 100
            setActiveState(state: true)
            if isDisableSelected {
                disableDisableTimer()
            }
        } else if sliderView.shiftSlider.floatValue != 0.0 {
            setActiveState(state: BLClient.isNightShiftEnabled)
        }
        setDescriptionText()
    }
    
    
    //MARK: User Interaction
    
    @IBAction func power(_ sender: Any) {
        if sliderView.shiftSlider.floatValue == 0.0 {
            shift(strength: 50)
        } else {
            shift(isEnabled: !activeState)
        }
        disableDisableTimer()
    }
    
    @IBAction func disableHour(_ sender: Any) {
        if !isDisableSelected {
            isDisableSelected = true
            shift(isEnabled: false)
            disableHourMenuItem.state = NSOnState
            disableHourMenuItem.title = "Disabled for an hour"
            
            disableTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isDisableSelected = false
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
    }
    
    func disableDisableTimer() {
        disableTimer?.invalidate()
        isDisableSelected = false
        disableHourMenuItem.state = NSOffState
        disableHourMenuItem.title = "Disable for an hour"
    }
    
    func setActiveState(state: Bool) {
        activeState = state
        sliderView.shiftSlider.isEnabled = state
        
        if isDisableSelected {
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
        if isDisableSelected {
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
                descriptionText.title = "Enabled"
            } else {
                descriptionText.isHidden = true
            }
        case .sunSchedule:
            if !keepVisible {
                descriptionText.isHidden = !activeState
            }
            if activeState {
                descriptionText.title = "Enabled until sunrise"
            } else {
                descriptionText.title = "Disabled"
            }
        case .timedSchedule(_, let endTime):
            if !keepVisible {
                descriptionText.isHidden = !activeState
            }
            if activeState {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                let date = dateFormatter.string(from: endTime)
                
                descriptionText.title = "Enabled until \(date)"
            } else {
                descriptionText.title = "Disabled"
            }
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
        preferencesWindow.window?.orderFrontRegardless()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        if isDisableSelected {
            shift(isEnabled: true)
        }
        NSApplication.shared().terminate(self)
    }
}

