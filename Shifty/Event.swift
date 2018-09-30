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
    case unsupportedHardware

    //StatusMenuController
    case menuOpened
    case toggleNightShift(state: Bool)
    case disableForCurrentApp(state: Bool)
    case disableForHour(state: Bool)
    case disableForCustomTime(state: Bool, timeInterval: Int?)
    case disableForDomain(state: Bool)
    case disableForSubdomain(state: Bool)
    case preferencesWindowOpened
    case quitShifty

    //SliderView
    case enableSlider
    case sliderMoved(value: Float)

    //Preferences
    case preferences(autoLaunch: Bool, quickToggle: Bool, iconSwitching: Bool, syncDarkMode: Bool, websiteShifting: Bool, trueToneControl: Bool, schedule: ScheduleType)
    case shortcuts(toggleNightShift: Bool, increaseColorTemp: Bool, decreaseColorTemp: Bool, disableApp: Bool, disableDomain: Bool, disableSubdomain: Bool, disableHour: Bool, disableCustom: Bool, toggleTrueTone: Bool, toggleDarkMode: Bool)
    case websiteButtonClicked
    case feedbackButtonClicked
    case twitterButtonClicked
    case translateButtonClicked
    case donateButtonClicked
    case checkForUpdatesClicked
    case creditsClicked

    //Errors
    case accessibilityRevokedAlertShown
}


extension Event {

    func record() {
        if PrefManager.shared.userDefaults.bool(forKey: Keys.fabricCrashlyticsPermission) {
            #if !DEBUG
                Answers.logCustomEvent(withName: eventName, customAttributes: customAttributes)
            #endif
        }
    }

    private var eventName: String {
        switch(self) {
        case .appLaunched: return "App Launched"
        case .oldMacOSVersion(_): return "Unsupported version of macOS"
        case .unsupportedHardware: return "Unsupported Hardware"
        case .menuOpened: return "Menu opened"
        case .toggleNightShift: return "Night Shift Toggled"
        case .disableForCurrentApp(_): return "Disable for current app clicked"
        case .disableForDomain(_): return "Disable for domain clicked"
        case .disableForSubdomain(_): return "Disable for subdomain clicked"
        case .disableForHour(_): return" Disable for hour clicked"
        case .disableForCustomTime(_, _): return "Disable for custom time clicked"
        case .preferencesWindowOpened: return "Preferences window opened"
        case .quitShifty: return "Quit button clicked"
        case .enableSlider: return "Enable slider button clicked"
        case .sliderMoved(_): return "Slider moved"
        case .preferences: return "Preferences"
        case .shortcuts: return "Shortcuts"
        case .websiteButtonClicked: return "Website button clicked"
        case .feedbackButtonClicked: return "Feedback button clicked"
        case .twitterButtonClicked: return "Twitter button clicked"
        case .translateButtonClicked: return "Translate button clicked"
        case .donateButtonClicked: return "Donate button clicked"
        case .checkForUpdatesClicked: return "Check for updates button clicked"
        case .creditsClicked: return "Credits button clicked"
        case .accessibilityRevokedAlertShown: return "Accessibility permissions revoked alert shown"
        }
    }

    private var customAttributes: [String: Any]? {
        switch(self) {
        case .oldMacOSVersion(let version):
            return ["Version": version]
        case .toggleNightShift(let state):
            return ["State": state ? "true" : "false"]
        case .disableForCurrentApp(let state):
            return ["State": state ? "true" : "false"]
        case .disableForDomain(let state):
            return ["State": state ? "true" : "false"]
        case .disableForSubdomain(let state):
            return ["State" : state ? "true" : "false"]
        case .disableForHour(let state):
            return ["State": state ? "true" : "false"]
        case .disableForCustomTime(let state, let timeInterval):
            return ["State": state ? "true" : "false",
                "Time interval in minutes": String(describing: timeInterval)]
        case .sliderMoved(let value):
            return ["Slider value": value]
        case .shortcuts(let toggleNightShift, let increaseColorTemp, let decreaseColorTemp, let disableApp, let disableDomain, let disableSubdomain, let disableHour, let disableCustom, let toggleTrueTone, let toggleDarkMode):
            return ["Toggle Night Shift": toggleNightShift ? "true" : "false",
                    "Increase color temp": increaseColorTemp ? "true" : "false",
                    "Decrease color temp": decreaseColorTemp ? "true" : "false",
                    "Disable for current app": disableApp ? "true" : "false",
                    "Disable for domain": disableDomain ? "true" : "false",
                    "Disable for subdomain": disableSubdomain ? "true" : "false",
                    "Disable for an hour": disableHour ? "true" : "false",
                    "Disable for custom time": disableCustom ? "true" : "false",
                    "Toggle True Tone": toggleTrueTone ? "true" : "false",
                    "Toggle dark mode": toggleDarkMode ? "true" : "false"]
        case .preferences(let autoLaunch, let quickToggle, let iconSwitching, let syncDarkMode, let websiteShifting, let trueToneControl, let schedule):
            var scheduleString: String
            switch schedule {
            case .off: scheduleString = "off"
            case .solar: scheduleString = "sunset to sunrise"
            case .custom(_, _): scheduleString = "custom"
            }
            return ["Auto Launch": autoLaunch ? "true" : "false",
                    "Quick Toggle": quickToggle ? "true" : "false",
                    "Icon Switching": iconSwitching ? "true" : "false",
                    "Sync Dark Mode": syncDarkMode ? "true" : "false",
                    "Website shifting" : websiteShifting ? "true" : "false",
                    "True Tone control" : trueToneControl ? "true" : "false",
                    "Schedule": scheduleString]
        default:
            return nil
        }
    }
}
