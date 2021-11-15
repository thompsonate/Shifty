//
//  SwitchView.swift
//  Shifty
//
//  Created by Nate Thompson on 11/11/21.
//

import Cocoa

@available(macOS 11.0, *)
class SwitchView: NSView {
    private var toggleSwitch = NSSwitch()
    private var onSwitchToggle: (Bool) -> Void
    
    var switchState: Bool {
        didSet {
            toggleSwitch.state = switchState ? .on : .off
        }
    }
    
    init(title: String, onSwitchToggle: @escaping (Bool) -> Void) {
        self.switchState = false
        self.onSwitchToggle = onSwitchToggle
        super.init(frame: .zero)
        
        let label = NSTextField()
        label.stringValue = title
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.isEditable = false
        label.isBezeled = false
        label.backgroundColor = .clear
        
        toggleSwitch.target = self
        toggleSwitch.action = #selector(switchToggled)
        
        let stackView = NSStackView(views: [label, toggleSwitch])
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .centerY
        
        self.addSubviewAndConstrainToEqualSize(
            stackView,
            withInsets: NSEdgeInsets(top: 5, left: 12, bottom: 5, right: 12))
        toggleSwitch.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func switchToggled() {
        switch toggleSwitch.state {
        case .on:
            onSwitchToggle(true)
        case .off:
            onSwitchToggle(false)
        default:
            onSwitchToggle(false)
        }
    }
}


extension NSView {
    func addSubviewAndConstrainToEqualSize(
        _ subview: NSView,
        withInsets insets: NSEdgeInsets,
        includeLayoutMargins: Bool = false)
    {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insets.right),
            subview.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top),
            subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
