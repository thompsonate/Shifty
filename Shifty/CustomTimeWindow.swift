//
//  CustomTimeWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/21/17.
//
//

import Cocoa

class OnlyIntValueFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.isEmpty {
            return true
        }
        if partialString.count > 3 {
            return false
        }
        return Int(partialString) != nil
    }
}

class CustomTimeWindow: NSWindowController {
    
    var disableCustomTime: ((Int) -> Void)?
    var customTimeWindowIsOpen: ((Bool) -> Void)?
    let onlyIntValueFormatter = OnlyIntValueFormatter()
    
    override var windowNibName: NSNib.Name {
        return NSNib.Name("CustomTimeWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.styleMask.remove(.resizable)
        self.window?.level = .floating
        self.window?.standardWindowButton(.closeButton)?.isHidden = true
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true
        
        hoursTextField.formatter = onlyIntValueFormatter
        minutesTextField.formatter = onlyIntValueFormatter
    }
    
    @IBOutlet weak var hoursTextField: NSTextField!
    @IBOutlet weak var minutesTextField: NSTextField!
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        window?.close()
    }
    
    @IBAction func okButtonClicked(_ sender: NSButton) {
        let hours = hoursTextField.intValue
        let minutes = minutesTextField.intValue
        let timeIntervalInSeconds = hours * 3600 + minutes * 60
        disableCustomTime?(Int(timeIntervalInSeconds))
        
        window?.close()
    }
}
