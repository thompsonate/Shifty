//
//  TrueToneClient+Shifty.swift
//  Shifty
//
//  Created by Nate Thompson on 9/4/18.
//

import Foundation

extension CBTrueToneClient {
    static var shared = CBTrueToneClient()
    
    var isTrueToneSupported: Bool {
        return CBTrueToneClient.shared.supported()
    }
    
    var isTrueToneAvailable: Bool {
        return CBTrueToneClient.shared.available()
    }
    
    var isTrueToneEnabled: Bool {
        get {
            return CBTrueToneClient.shared.enabled()
        }
        set {
            CBTrueToneClient.shared.setEnabled(newValue)
        }
    }
}
