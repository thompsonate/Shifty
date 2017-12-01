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
    static let isIconSwitchingEnabled = "isIconSwitchingEnabled"
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let lastKnownLocation = "lastKnownLocation"
    static let disabledApps = "disabledApps"
    static let browserRules = "browserRules"
    
    static let toggleNightShiftShortcut = "toggleNightShiftShortcut"
    static let incrementColorTempShortcut = "incrementColorTempShortcut"
    static let decrementColorTempShortcut = "decrementColorTempShortcut"
    static let disableAppShortcut = "disableAppShortcut"
    static let disableHourShortcut = "disableHourShortcut"
    static let disableCustomShortcut = "disableCustomShortcut"
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
            Keys.isIconSwitchingEnabled: NSNumber(value: false),
            Keys.isDarkModeSyncEnabled: NSNumber(value: false),
            Keys.disabledApps: [String](),
            Keys.browserRules: NSData()
            ] as [String : Any]
        
        userDefaults.register(defaults: factoryDefaults)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
    
    func reset() {
        userDefaults.removeObject(forKey: Keys.isAutoLaunchEnabled)
        userDefaults.removeObject(forKey: Keys.isStatusToggleEnabled)
        userDefaults.removeObject(forKey: Keys.isIconSwitchingEnabled)
        userDefaults.removeObject(forKey: Keys.isDarkModeSyncEnabled)
        userDefaults.removeObject(forKey: Keys.lastKnownLocation)
        userDefaults.removeObject(forKey: Keys.disabledApps)
        userDefaults.removeObject(forKey: Keys.browserRules)
        userDefaults.removeObject(forKey: Keys.toggleNightShiftShortcut)
        userDefaults.removeObject(forKey: Keys.incrementColorTempShortcut)
        userDefaults.removeObject(forKey: Keys.decrementColorTempShortcut)
        userDefaults.removeObject(forKey: Keys.disableAppShortcut)
        userDefaults.removeObject(forKey: Keys.disableHourShortcut)
        userDefaults.removeObject(forKey: Keys.disableCustomShortcut)
        
        synchronize()
    }
}


