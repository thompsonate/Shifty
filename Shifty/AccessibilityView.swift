//
//  AccessibilityView.swift
//  Shifty
//
//  Created by Nate Thompson on 1/1/18.
//

import Cocoa

class AccessibilityView: NSView {

    @IBOutlet var view: NSView!
    @IBOutlet weak var preferencesImageView: NSImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let nib = NSNib(nibNamed: "AccessibilityView", bundle: Bundle(for: type(of: self))) else { return }
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        
        var newConstraints: [NSLayoutConstraint] = []
        for oldConstraint in view.constraints {
            let firstItem = oldConstraint.firstItem === view ? self : oldConstraint.firstItem!
            let secondItem = oldConstraint.secondItem === view ? self : oldConstraint.secondItem
            newConstraints.append(NSLayoutConstraint(item: firstItem, attribute: oldConstraint.firstAttribute, relatedBy: oldConstraint.relation, toItem: secondItem, attribute: oldConstraint.secondAttribute, multiplier: oldConstraint.multiplier, constant: oldConstraint.constant))
        }
        
        for newView in view.subviews {
            self.addSubview(newView)
        }
        
        self.addConstraints(newConstraints)
        
        
        var imageName: String
        
        if let language = NSLocale.current.languageCode {
            imageName = "accessibilityScreenshot-\(language)"
            
            if let script = NSLocale.current.scriptCode {
                imageName.append("-\(script)")
            }
        } else {
            imageName = "accessibilityScreenshot-en"
        }
        
        preferencesImageView.image = NSImage(named: imageName)
    }
}
