//
//  Event.swift
//  Shifty
//
//  Created by Nate Thompson on 7/27/17.
//
//

import Foundation
import Fabric
import Crashlytics

enum Event {
    case appLaunched
    case oldMacOSVersion(version: String)
    
    //StatusMenuController
    case toggleNightShift(state: Bool)
    case disableForCurrentApp(state: Bool, app: String)
    case disableForHour(state: Bool)
    case disableForCustomTime(state: Bool, timeInterval: Int?)
    case aboutWindowOpened
    case preferencesWindowOpened
    case quitShifty
    
    //SliderView
    case enableSlider
    case sliderMoved(value: Float)
    
    //AboutWindow
    case checkForUpdatesClicked
    case websiteButtonClicked
    case feedbackButtonClicked
    
    //PreferencesWindow
    case autoLaunchOnLogin(isEnabled: Bool)
    case quickToggle(isEnabled: Bool)
}


extension Event {
    
    func record() {
        Answers.logCustomEvent(withName: eventName, customAttributes: customAttributes)
    }
    
    private var eventName: String {
        switch(self) {
        case .appLaunched: return "App Launched"
        case .oldMacOSVersion(_): return "Unsupported version of macOS"
        case .toggleNightShift: return "Night Shift Toggled"
        case .disableForCurrentApp(_, _): return "Disable for current app clicked"
        case .disableForHour(_): return" Disable for hour clicked"
        case .disableForCustomTime(_, _): return "Disable for custom time clicked"
        case .aboutWindowOpened: return "About window opened"
        case .preferencesWindowOpened: return "Preferences window opened"
        case .quitShifty: return "Quit button clicked"
        case .enableSlider: return "Enable slider button clicked"
        case .sliderMoved(_): return "Slider moved"
        case .checkForUpdatesClicked: return "Check for updates button clicked"
        case .websiteButtonClicked: return "Website button clicked"
        case .feedbackButtonClicked: return "Feedback button clicked"
        case .autoLaunchOnLogin(_): return "Auto launch on login preference changed"
        case .quickToggle(_): return "Quick Toggle preference changed"
        }
    }
    
    private var customAttributes: [String: Any]? {
        switch(self) {
        case .oldMacOSVersion(let version):
            return ["Version": version]
        case .toggleNightShift(let state):
            return ["State": state ? "true" : "false"]
        case .disableForCurrentApp(let state, let app):
            return ["State": state ? "true" : "false", "App Bundle ID": app]
        case .disableForHour(let state):
            return ["State": state ? "true" : "false"]
        case .disableForCustomTime(let state, let timeInterval):
            return ["State": state ? "true" : "false", "Time interval in minutes": String(describing: timeInterval)]
        case .sliderMoved(let value):
            return ["Slider value": value]
        case .autoLaunchOnLogin(let isEnabled):
            return ["Is enabled": isEnabled ? "true" : "false"]
        case .quickToggle(let isEnabled):
            return ["Is enabled": isEnabled ? "true" : "false"]
        default:
            return nil
        }
    }
}
