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


class NSSliderWithScroll: NSSlider {
    override func scrollWheel(with event: NSEvent) {
        let range = Float(self.maxValue - self.minValue)
        var delta = Float(event.deltaY - event.deltaX)
        if event.isDirectionInvertedFromDevice {
            delta *= -1
        }
        
        let increment = range * delta / 100
        let value = self.floatValue + increment
        
        self.floatValue = value
        self.sendAction(self.action, to: self.target)
    }
}
