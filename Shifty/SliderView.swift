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
    
    @IBAction func shiftSliderMoved(_ sender: NSSlider) {
        StatusMenuController().shift(strength: shiftSlider.floatValue)
    }
}
