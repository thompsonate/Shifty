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
}

class StatusMenuController: NSObject {
    
    var preferencesWindow: PreferencesWindow!
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    
    var sliderMenuItem: NSMenuItem!
    var activeState = true
    var isTimerEnabled = false
    var timer: Timer!
    
    override func awakeFromNib() {
        preferencesWindow = PreferencesWindow()
        sliderMenuItem = statusMenu.item(withTitle: "Slider")
        sliderMenuItem.view = sliderView

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
        
        sliderView.shiftSlider.floatValue = BLClient.strength * 100
//        if client is not enabled {
//            activeState = false
//            powerMenuItem.title = "Turn On"
//            sliderView.shiftSlider.isEnabled = false
//        }
    }
    
    @IBAction func power(_ sender: Any) {
        shift(isEnabled: activeState)

    }
    
    @IBAction func disableHour(_ sender: Any) {
        if !isTimerEnabled {
            isTimerEnabled = true
            shift(isEnabled: false)
            disableHourMenuItem.state = NSOnState
            disableHourMenuItem.title = "Disabled for an hour"
            timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { _ in
                self.isTimerEnabled = false
                self.shift(isEnabled: true)
                self.disableHourMenuItem.state = NSOffState
                self.disableHourMenuItem.title = "Disable for an hour"
            }
            timer.tolerance = 60
        } else {
            timer.invalidate()
            isTimerEnabled = false
            shift(isEnabled: true)
            disableHourMenuItem.state = NSOffState
            disableHourMenuItem.title = "Disable for an hour"

        }
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            BLClient.setStrength(strength/100, commit: true)
            if activeState == true {
                activeState = true
                powerMenuItem.title = "Turn Off"
            }
        } else {
            activeState = false
            powerMenuItem.title = "Turn On"
        }
        BLClient.setEnabled(strength/100 != 0.0)
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            let sliderValue = sliderView.shiftSlider.floatValue
            BLClient.setStrength(sliderValue/100, commit: true)
            BLClient.setEnabled(true)
            activeState = true
            powerMenuItem.title = "Turn Off"
            sliderView.shiftSlider.isEnabled = true
            
            if isTimerEnabled {
                timer.invalidate()
                isTimerEnabled = false
                disableHourMenuItem.state = NSOffState
                disableHourMenuItem.title = "Disable for an hour"
            }
        } else {
            BLClient.setEnabled(false)
            activeState = false
            powerMenuItem.title = "Turn On"
            sliderView.shiftSlider.isEnabled = false
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}

