//
//  PrefManager.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

struct Keys {
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
    static let isAutoLaunchEnabled = "isAutoLaunchEnabled"
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let lastKnownLocation = "lastKnownLocation"
    static let disabledApps = "disabledApps"
}


class PrefManager {
    static let sharedInstance = PrefManager()
    
    private init() {
        registerFactoryDefaults()
    }
    
    let userDefaults = UserDefaults.standard
    
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.isAutoLaunchEnabled: NSNumber(value: false),
            Keys.isStatusToggleEnabled: NSNumber(value: false),
            Keys.isDarkModeSyncEnabled: NSNumber(value: false),
            Keys.disabledApps: [String]()
            ] as [String : Any]
        
        userDefaults.register(defaults: factoryDefaults)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
    
    func reset() {
        userDefaults.removeObject(forKey: Keys.isAutoLaunchEnabled)
        userDefaults.removeObject(forKey: Keys.isStatusToggleEnabled)
        userDefaults.removeObject(forKey: Keys.isDarkModeSyncEnabled)
        userDefaults.removeObject(forKey: Keys.lastKnownLocation)
        userDefaults.removeObject(forKey: Keys.disabledApps)
        
        synchronize()
    }
}
