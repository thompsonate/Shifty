//
//  AnalyticsDetailViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 9/22/18.
//

import Cocoa

class AnalyticsDetailViewController: NSViewController {
    
    @IBOutlet weak var label: NSTextField!
    
    override var nibName: NSNib.Name {
        return "AnalyticsDetailView"
    }
    
    override func viewDidLoad() {
        let dataIncludesList = [
            "Information about what caused a crash",
            "Data about the usage of various features in Shifty",
            "Useful information about issues that don’t cause the app to crash\n"
        ]
        
        let dataDoesNotIncludeList = [
            "Sensitive data Shifty is granted permission to access (e.g. web addresses used for Website Shifting)",
            "Any device IDs or personally identifiable information\n"
        ]
        
        let dataUsageList = [
            "All data collected is anonymous and aggregated, so it cannot be traced back to individual users",
            "None of this data is sold to anyone (and nobody would want to buy it anyways)"
        ]
        
        let mutableString = NSMutableAttributedString()
        mutableString.append(add(title: "What data is collected?"))
        mutableString.append(add(stringList: dataIncludesList))
        mutableString.append(add(title: "What data isn't collected?"))
        mutableString.append(add(stringList: dataDoesNotIncludeList))
        mutableString.append(add(title: "What happens to the data?"))
        mutableString.append(add(stringList: dataUsageList))
        
        label.attributedStringValue = NSAttributedString(attributedString: mutableString)
    }
    
    @IBAction func closePressed(_ sender: Any) {
        dismiss(sender)
    }
    
    func add(title: String,
             font: NSFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
             lineSpacing: CGFloat = 0,
             paragraphSpacing: CGFloat = 6,
             textColor: NSColor = .labelColor) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = paragraphSpacing
        
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        let formattedString = "\(title)\n"
        
        return NSAttributedString(string: formattedString, attributes: textAttributes)
    }
    
    func add(stringList: [String],
             font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize),
             bullet: String = "\u{2022}",
             indentation: CGFloat = 20,
             lineSpacing: CGFloat = 0,
             paragraphSpacing: CGFloat = 6,
             textColor: NSColor = .labelColor,
             bulletColor: NSColor = .labelColor) -> NSAttributedString {
        
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: bulletColor]
        
        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        
        let bulletList = NSMutableAttributedString()
        for string in stringList {
            let formattedString = "\(bullet)\t\(string)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)
            
            attributedString.addAttributes(
                [NSAttributedString.Key.paragraphStyle : paragraphStyle],
                range: NSMakeRange(0, attributedString.length))
            
            attributedString.addAttributes(
                textAttributes,
                range: NSMakeRange(0, attributedString.length))
            
            let string:NSString = NSString(string: formattedString)
            let rangeForBullet:NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }
        
        return bulletList
    }
}



