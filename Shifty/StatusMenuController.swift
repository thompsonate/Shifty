//
//  StatusMenuController.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa

class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    let client = CBBlueLightClient()
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    var preferencesWindow: PreferencesWindow!
    
    @IBOutlet weak var powerMenuItem: NSMenuItem!
    @IBOutlet weak var disableHourMenuItem: NSMenuItem!
    @IBOutlet weak var sliderView: SliderView!
    
    var sliderMenuItem: NSMenuItem!
    var activeState = true
    var isTimerEnabled = false
    var timer: Timer!
    
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        preferencesWindow = PreferencesWindow()
        
        sliderMenuItem = statusMenu.item(withTitle: "Slider")
        sliderMenuItem.view = sliderView

        sliderView.sliderValueChanged = {(sliderValue) in
            self.shift(strength: sliderValue)
        }
        
        sliderView.sliderEnabled = { _ in
            self.shift(isEnabled: true)
        }
        
        shift(strength: 50)
        sliderView.shiftSlider.floatValue = 50
    }
    
    @IBAction func power(_ sender: NSMenuItem) {
        if activeState {
            shift(isEnabled: false)
        } else {
            shift(isEnabled: true)
        }
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
            client.setStrength(strength/100, commit: true)
            if activeState == true {
                activeState = true
                powerMenuItem.title = "Turn Off"
            }
        } else {
            activeState = false
            powerMenuItem.title = "Turn On"
        }
        client.setEnabled(strength/100 != 0.0)
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            let sliderValue = sliderView.shiftSlider.floatValue
            client.setStrength(sliderValue/100, commit: true)
            client.setEnabled(true)
            activeState = true
            powerMenuItem.title = "Turn Off"
            sliderView.shiftSlider.isEnabled = true
            
            if isTimerEnabled {
                timer.invalidate()
                disableHourMenuItem.state = NSOffState
                disableHourMenuItem.title = "Disable for an hour"
            }
        } else {
            client.setEnabled(false)
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

