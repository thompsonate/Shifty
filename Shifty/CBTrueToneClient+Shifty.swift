//
//  CBTrueToneClient+Shifty.swift
//  Shifty
//
//  Created by Nate Thompson on 9/4/18.
//

import Foundation
import SwiftLog

enum State {
    case unsupported
    case unavailable
    case enabled
    case disabled
}

extension CBTrueToneClient {
    static var shared = CBTrueToneClient()
    
    private var isTrueToneSupported: Bool {
        return CBTrueToneClient.shared.supported()
    }
    
    private var isTrueToneAvailable: Bool {
        return CBTrueToneClient.shared.available()
    }
    
    var isTrueToneEnabled: Bool {
        get {
            return CBTrueToneClient.shared.enabled()
        }
        set {
            CBTrueToneClient.shared.setEnabled(newValue)
            logw("True Tone set to \(newValue)")
        }
    }
    
    var state: State {
        if !isTrueToneSupported { return .unsupported }
        else if !isTrueToneAvailable { return .unavailable }
        else if isTrueToneEnabled { return .enabled }
        else { return .disabled }
    }
}
