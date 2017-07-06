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
    
    @IBOutlet weak var sliderView: SliderView!
    var sliderMenuItem: NSMenuItem!
    //var powerMenuItem: NSMenuItem!
    var activeState = false
    
    
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
        
        //powerMenuItem = statusMenu.item(withTag: 1)
        shift(isEnabled: false)
    }
    
    @IBAction func power(_ sender: NSMenuItem) {
        if activeState {
            shift(isEnabled: false)
        } else {
            shift(isEnabled: true)
        }
            
        shift(strength: 0.75)
    }
    
    func shift(strength: Float) {
        if strength != 0.0 {
            client.setStrength(strength/100, commit: true)
            if activeState == true {
                activeState = true
                powerMenuItem.title = "Turn On"
            }
        } else {
            activeState = false
            powerMenuItem.title = "Turn Off"
        }
        client.setEnabled(strength/100 != 0.0)
    }
    
    @IBAction func disableHour(_ sender: Any) {
        shift(isEnabled: false)
        let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
            self.shift(isEnabled: true)
        }
    }
    
    func shift(isEnabled: Bool) {
        if isEnabled {
            client.setEnabled(true)
            activeState = true
            powerMenuItem.title = "Turn Off"
        } else {
            client.setEnabled(false)
            activeState = false
            powerMenuItem.title = "Turn On"
        }
    }
    
    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}

