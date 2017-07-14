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
    var sliderEnabled: ((Void) -> Void)?
    
    @IBAction func shiftSliderMoved(_ sender: NSSlider) {
        sliderValueChanged?(sender.floatValue)
    }
    
    @IBAction func clickEnableSlider(_ sender: Any) {
        shiftSlider.isEnabled = true
        sliderEnabled?()
    }
}
