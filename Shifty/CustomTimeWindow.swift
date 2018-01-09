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
        
        if UserDefaults.standard.value(forKey: "customTimeWindowFrame") == nil {
            window?.center()
        }
        
        let saveName = NSWindow.FrameAutosaveName.init("customTimeWindowFrame")
        
        window?.setFrameUsingName(saveName)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NSWindowWillCloseNotification"), object: nil, queue: nil) { _ in
            self.window?.saveFrame(usingName: saveName)
        }
        
        window?.level = .floating
        window?.titleVisibility = .hidden
        
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
