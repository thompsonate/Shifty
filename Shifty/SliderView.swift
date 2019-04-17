//
//  SliderView.swift
//  Shifty
//
//  Created by Nate Thompson on 5/7/17.
//
//

import Cocoa
import SwiftLog

class SliderView: NSView {

    @IBOutlet weak var shiftSlider: NSSlider!

    @IBAction func shiftSliderMoved(_ sender: NSSlider) {
        let event = NSApplication.shared.currentEvent
        
        if event?.type == .leftMouseUp {
            NightShiftManager.blueLightReductionAmount = sender.floatValue / 100
            
            sender.superview?.enclosingMenuItem?.menu?.cancelTracking()
            Event.sliderMoved(value: sender.floatValue).record()
            logw("Slider set to \(sender.floatValue)")
        } else {
            NightShiftManager.previewBlueLightReductionAmount(sender.floatValue / 100)
        }
    }

    @IBAction func clickEnableSlider(_ sender: Any) {
        NightShiftManager.respond(to: .userEnabledNightShift)
        
        let statusMenuController = (NSApplication.shared.delegate as! AppDelegate).statusMenu.delegate as! StatusMenuController
        statusMenuController.configureMenuItems()
        statusMenuController.setDescriptionText(keepVisible: true)
        
        shiftSlider.isEnabled = true
        Event.enableSlider.record()
        logw("Enable slider button clicked")
    }
}


class ScrollableSlider: NSSlider {
    override func scrollWheel(with event: NSEvent) {
        guard isEnabled else { return }

        let range = maxValue - minValue
        var delta: CGFloat = 0.0

        //Allow horizontal scrolling on horizontal and circular sliders
        if self.isVertical && self.sliderType == .linear {
            delta = event.deltaY
        } else if self.userInterfaceLayoutDirection == .rightToLeft {
            delta = event.deltaY + event.deltaX
        } else {
            delta = event.deltaY - event.deltaX
        }

        //Account for natural scrolling
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }

        let increment = range * Double(delta) / 100
        var value = doubleValue + increment

        //Wrap around if slider is circular
        if sliderType == .circular {
            let minValue = self.minValue
            let maxValue = self.maxValue

            if value < minValue {
                value = maxValue - abs(increment)
            }
            if value > maxValue {
                value = minValue + abs(increment)
            }
        }

        self.doubleValue = value
        self.sendAction(action, to: target)
    }
}
