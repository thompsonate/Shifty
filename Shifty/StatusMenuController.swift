//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

let BLClient = CBBlueLightClient()

extension CBBlueLightClient {
    var strength: Float {
        var strength: Float = 0.0
        self.getStrength(&strength)
        return strength
    }
    
    var CCT: Float {
        var CCT: Float = 0.0
        self.getCCT(&CCT)
        return CCT
    }
    
    var isNightShiftEnabled: Bool {
        return getBooleanFromBlueLightStatus(index: 1)
    }
    
    func getBooleanFromBlueLightStatus(index: Int) -> Bool {
        //create an empty mutable OpaquePointer
        let string = "000000000000000000000000000000"
        var data = string.data(using: .utf8)!
        let ints: UnsafeMutablePointer<Int>! = data.withUnsafeMutableBytes{ $0 }
        let bytes = OpaquePointer(ints)
        
        //load the BlueLightStatus struct into the opaque pointer
        self.getBlueLightStatus(bytes)
        
        //get the byes from the BlueLightStatus pointer
        let intsArray = [UInt8](data)
        
        //passes in index parameter
        return intsArray[index] == 1
    }
}

// MARK: - StatusMenuController

class StatusMenuController: NSObject {
    
    var preferencesWindow: PreferencesWindow!
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    @IBOutlet weak var sunIcon: NSImageView!
    @IBOutlet weak var moonIcon: NSImageView!
    
    var sliderMenuItem: NSMenuItem!
    var activeState = true
    var isDisableSelected = false
    var disableTimer: Timer!
    var updateInterfaceTimer: Timer!
    
    override func awakeFromNib() {
        preferencesWindow = PreferencesWindow()
        sliderMenuItem = statusMenu.item(withTitle: "Slider")
        sliderMenuItem.view = sliderView
        sunIcon.image?.isTemplate = true
        moonIcon.image?.isTemplate = true

        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
        }
        
        sliderView.sliderEnabled = { _ in
            self.shift(isEnabled: true)
        }
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        appDelegate.statusItemClicked = { _ in
            self.power(self)
        }
        
        self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
        self.setActiveState(state: BLClient.isNightShiftEnabled)
        updateInterface()
    }
    
    
    //MARK: User Interaction
    
    @IBAction func power(_ sender: Any) {
        shift(isEnabled: !activeState)

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
        } else {
            disableTimer.invalidate()
            isDisableSelected = false
            shift(isEnabled: true)
            disableHourMenuItem.state = NSOffState
            disableHourMenuItem.title = "Disable for an hour"
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func setActiveState(state: Bool) {
        activeState = state
        sliderView.shiftSlider.isEnabled = state
        if state {
            powerMenuItem.title = "Turn Off Night Shift"
        } else {
            powerMenuItem.title = "Turn On Night Shift"
        }
    }
    
    func updateInterface() {
        var strength = BLClient.strength
        var state = BLClient.isNightShiftEnabled
        updateInterfaceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let newStrength = BLClient.strength
            let newState = BLClient.isNightShiftEnabled
            if newStrength != strength {
                self.sliderView.shiftSlider.floatValue = BLClient.strength * 100
                strength = newStrength
            }
            if self.isDisableSelected {
                self.disableTimer.invalidate()
                self.isDisableSelected = false
                self.disableHourMenuItem.state = NSOffState
                self.disableHourMenuItem.title = "Disable for an hour"
            } else {
                if newState != state {
                    self.setActiveState(state: newState)
                    state = newState
                }
            }
        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            BLClient.setStrength(strength/100, commit: true)
            if activeState == true {
                activeState = true
                powerMenuItem.title = "Turn Off Night Shift"
            }
        } else {
            activeState = false
            powerMenuItem.title = "Turn On Night Shift"
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
            
            if isDisableSelected {
                disableTimer.invalidate()
                isDisableSelected = false
                disableHourMenuItem.state = NSOffState
                disableHourMenuItem.title = "Disable for an hour"
            }
        } else {
            BLClient.setEnabled(false)
            activeState = false
            powerMenuItem.title = "Turn On Night Shift"
            sliderView.shiftSlider.isEnabled = false
        }
    }
}

