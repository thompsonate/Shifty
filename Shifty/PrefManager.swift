//
//  PrefManager.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

enum Keys {
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
    static let isAutoLaunchEnabled = "isAutoLaunchEnabled"
    static let isIconSwitchingEnabled = "isIconSwitchingEnabled"
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let isWebsiteControlEnabled = "isWebsiteControlEnabled"
    static let trueToneControl = "trueToneControl"
    static let fabricCrashlyticsPermission = "fabricCrashlyticsPermission"
    static let disabledApps = "disabledApps"
    static let browserRules = "browserRules"

    static let toggleNightShiftShortcut = "toggleNightShiftShortcut"
    static let incrementColorTempShortcut = "incrementColorTempShortcut"
    static let decrementColorTempShortcut = "decrementColorTempShortcut"
    static let disableAppShortcut = "disableAppShortcut"
    static let disableDomainShortcut = "disableDomainShortcut"
    static let disableSubdomainShortcut = "disableSubdomainShortcut"
    static let disableHourShortcut = "disableHourShortcut"
    static let disableCustomShortcut = "disableCustomShortcut"
    static let toggleTrueToneShortcut = "toggleTrueToneShortcut"
    static let toggleDarkModeShortcut = "toggleDarkModeShortcut"
    
    static let lastInstalledShiftyVersion = "lastInstalledShiftyVersion"
    static let dateLastCheckedForUpdates = "dateLastCheckedForUpdates"
    static let hasSetupWindowShown = "hasSetupWindowShown"
}


class PrefManager {
    static let shared = PrefManager()

    private init() {
        registerFactoryDefaults()
    }

    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
        
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.isAutoLaunchEnabled: NSNumber(value: false),
            Keys.isStatusToggleEnabled: NSNumber(value: false),
            Keys.isIconSwitchingEnabled: NSNumber(value: false),
            Keys.isDarkModeSyncEnabled: NSNumber(value: false),
            Keys.isWebsiteControlEnabled: NSNumber(value: false),
            Keys.trueToneControl: NSNumber(value: false),
            Keys.fabricCrashlyticsPermission: NSNumber(value: false),
            Keys.disabledApps: NSData(),
            Keys.browserRules: NSData(),
            Keys.dateLastCheckedForUpdates: Date.distantPast,
            Keys.hasSetupWindowShown: NSNumber(value: false)
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
        userDefaults.removeObject(forKey: Keys.isWebsiteControlEnabled)
        userDefaults.removeObject(forKey: Keys.trueToneControl)
        userDefaults.removeObject(forKey: Keys.disabledApps)
        userDefaults.removeObject(forKey: Keys.browserRules)
        userDefaults.removeObject(forKey: Keys.toggleNightShiftShortcut)
        userDefaults.removeObject(forKey: Keys.incrementColorTempShortcut)
        userDefaults.removeObject(forKey: Keys.decrementColorTempShortcut)
        userDefaults.removeObject(forKey: Keys.disableAppShortcut)
        userDefaults.removeObject(forKey: Keys.disableDomainShortcut)
        userDefaults.removeObject(forKey: Keys.disableSubdomainShortcut)
        userDefaults.removeObject(forKey: Keys.disableHourShortcut)
        userDefaults.removeObject(forKey: Keys.disableCustomShortcut)
        userDefaults.removeObject(forKey: Keys.toggleTrueToneShortcut)
        userDefaults.removeObject(forKey: Keys.toggleDarkModeShortcut)
        userDefaults.removeObject(forKey: Keys.fabricCrashlyticsPermission)
        userDefaults.removeObject(forKey: Keys.dateLastCheckedForUpdates)
        userDefaults.removeObject(forKey: Keys.hasSetupWindowShown)
        
        synchronize()
    }
}
