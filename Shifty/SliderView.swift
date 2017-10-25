//
//  SliderView.swift
//  Shifty
//
//  Created by Nate Thompson on 5/7/17.
//
//

import Cocoa

class SliderView: NSView {
    
    @IBOutlet weak var shiftSlider: NSSlider!
    var sliderValueChanged: ((Float) -> Void)?
    var sliderEnabled: (() -> Void)?
    
    @IBAction func shiftSliderMoved(_ sender: NSSlider) {
        sliderValueChanged?(sender.floatValue)
        let event = NSApplication.shared.currentEvent
        if event?.type == NSEvent.EventType.leftMouseUp {
            Event.sliderMoved(value: sender.floatValue).record()
        }
    }
    
    @IBAction func clickEnableSlider(_ sender: Any) {
        shiftSlider.isEnabled = true
        sliderEnabled?()
        Event.enableSlider.record()
    }
}


class ScrollableSlider: NSSlider {
    override func scrollWheel(with event: NSEvent) {
        guard self.isEnabled else { return }
        
        let range = Float(self.maxValue - self.minValue)
        var delta = Float(0)
        
        //Allow horizontal scrolling on horizontal and circular sliders
        if self.isVertical && self.sliderType == .linear {
            delta = Float(event.deltaY)
        } else if self.userInterfaceLayoutDirection == .rightToLeft {
            delta = Float(event.deltaY + event.deltaX)
        } else {
            delta = Float(event.deltaY - event.deltaX)
        }
        
        //Account for natural scrolling
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }
        
        let increment = range * delta / 100
        var value = self.floatValue + increment
        
        //Wrap around if slider is circular
        if self.sliderType == .circular {
            let minValue = Float(self.minValue)
            let maxValue = Float(self.maxValue)
            
            if value < minValue {
                value = maxValue - fabs(increment)
            }
            if value > maxValue {
                value = minValue + fabs(increment)
            }
        }
        
        self.floatValue = value
        self.sendAction(self.action, to: self.target)
    }
}
