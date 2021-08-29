//
//  NightShiftManager.swift
//  Shifty
//
//  Created by Saagar Jha on 1/13/18.
//

import Cocoa
import SwiftLog


class NightShiftManager {
    static let shared = NightShiftManager()
    let client = CBBlueLightClient.shared

    var userSet: UserSet = .notSet
    var userInitiatedShift = false
    
    static var supportsNightShift: Bool {
        CBBlueLightClient.supportsNightShift
    }
    
    var isNightShiftEnabled: Bool {
        get {
            client.isNightShiftEnabled
        }
        set {
            setNightShiftEnabled(to: newValue)
        }
    }
    
    var colorTemperature: Float {
        get {
            client.blueLightReductionAmount
        }
        set {
            client.blueLightReductionAmount = newValue
        }
    }
    
    var schedule: ScheduleType {
        get {
            client.schedule
        }
        set {
            client.schedule = newValue
        }
    }
    
    var nightShiftDisableTimer = DisableTimer.off {
        willSet {
            switch nightShiftDisableTimer {
            case .hour(let timer, _), .custom(let timer, _):
                timer.invalidate()
            default: break
            }
        }
    }
    
    var isDisabledWithTimer: Bool {
        return nightShiftDisableTimer != .off
    }
    
    /// When true, app or website rule has disabled Night Shift
    var isDisableRuleActive: Bool {
        return RuleManager.shared.disableRuleIsActive
    }

    init() {
        var prevSchedule = client.schedule
        
        updateDarkMode()
        
        // @convention block called by CoreBrightness
        client.setStatusNotificationBlock {
            if self.schedule == prevSchedule {
                self.respond(to: self.isNightShiftEnabled
                        ? .enteredScheduledNightShift : .exitedScheduledNightShift)
            } else {
                self.respond(to: .scheduleChanged)
                prevSchedule = CBBlueLightClient.shared.schedule
            }
            
            self.updateDarkMode()

            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.updateMenuBarIcon()
                
                let prefWindow = appDelegate.preferenceWindowController
                let prefGeneral = prefWindow.viewControllers.compactMap { childViewController in
                    return childViewController as? PrefGeneralViewController
                }.first
                prefGeneral?.updateSchedule?()
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
            logw("Wake from sleep notification posted")
            
            if CBBlueLightClient.shared.scheduledState !=
                CBBlueLightClient.shared.isNightShiftEnabled
            {
                self.respond(to: CBBlueLightClient.shared.scheduledState
                        ? .enteredScheduledNightShift : .exitedScheduledNightShift)
            }
            
            self.updateDarkMode()
        }
    }
    
    func updateDarkMode() {
        if UserDefaults.standard.bool(forKey: Keys.isDarkModeSyncEnabled) {
            let scheduledState = client.scheduledState
            
            switch client.schedule {
            case .off:
                let darkModeState = isNightShiftEnabled || isDisableRuleActive || isDisabledWithTimer || userSet == .on
                SLSSetAppearanceThemeLegacy(darkModeState)
                logw("Dark mode set to \(darkModeState)")
            case .solar:
                SLSSetAppearanceThemeLegacy(scheduledState)
                logw("Dark mode set to \(scheduledState)")
            case .custom(start: _, end: _):
                SLSSetAppearanceThemeLegacy(scheduledState)
                logw("Dark mode set to \(scheduledState)")
            }
        }
    }
    
    func setNightShiftEnabled(to state: Bool) {
        respond(to: state ? .userEnabledNightShift : .userDisabledNightShift)
    }

    func respond(to event: NightShiftEvent) {
        //Prevent BlueLightNotification from triggering one of these two events after every event
        if event == .enteredScheduledNightShift || event == .exitedScheduledNightShift {
            if userInitiatedShift {
                userInitiatedShift = false
                return
            } else {
                userInitiatedShift = false
            }
        } else {
            userInitiatedShift = true
        }
        
        switch event {
        case .enteredScheduledNightShift:
            userSet = .notSet
            if isDisabledWithTimer || isDisableRuleActive {
                client.setNightShiftEnabled(false)
            }
        case .exitedScheduledNightShift:
            userSet = .notSet
        case .userEnabledNightShift:
            userSet = .on
            nightShiftDisableTimer = .off
            
            if isDisableRuleActive {
                RuleManager.shared.removeRulesForCurrentState()
            }
            client.setNightShiftEnabled(true)
        case .userDisabledNightShift:
            client.setNightShiftEnabled(false)
            userSet = .off
        case .nightShiftDisableRuleActivated:
            client.setNightShiftEnabled(false)
            if UserDefaults.standard.bool(forKey: Keys.trueToneControl) {
                if #available(macOS 10.14, *) {
                    CBTrueToneClient.shared.isTrueToneEnabled = false
                }
            }
        case .nightShiftDisableRuleDeactivated:
            if !isDisabledWithTimer && !isDisableRuleActive {
                switch userSet {
                case .notSet:
                    client.setToSchedule()
                case .on:
                    client.setNightShiftEnabled(true)
                case .off:
                    client.setNightShiftEnabled(false)
                }
            }
            
            if !isDisableRuleActive && UserDefaults.standard.bool(forKey: Keys.trueToneControl) {
                if #available(macOS 10.14, *) {
                    CBTrueToneClient.shared.isTrueToneEnabled = true
                }
            }
        case .nightShiftEnableRuleActivated:
            switch userSet {
            case .on, .notSet:
                client.setNightShiftEnabled(true)
            case .off:
                client.setNightShiftEnabled(false)
            }
        case .nightShiftEnableRuleDeactivated:
            if isDisabledWithTimer || isDisableRuleActive {
                client.setNightShiftEnabled(false)
            } else {
                client.setToSchedule()
            }
        case .nightShiftDisableTimerStarted:
            client.setNightShiftEnabled(false)
        case .nightShiftDisableTimerEnded:
            if !isDisableRuleActive {
                switch userSet {
                case .notSet:
                    client.setToSchedule()
                case .on:
                    client.setNightShiftEnabled(true)
                case .off:
                    client.setNightShiftEnabled(false)
                }
            }
        case .scheduleChanged:
            userSet = .notSet
            client.setToSchedule()
        }
        logw("Responded to event: \(event)")
    }
    
    
    enum UserSet {
        case notSet
        case on
        case off
    }
}

enum NightShiftEvent {
    case enteredScheduledNightShift
    case exitedScheduledNightShift
    case userEnabledNightShift
    case userDisabledNightShift
    case nightShiftDisableTimerStarted
    case nightShiftDisableTimerEnded
    case nightShiftDisableRuleActivated
    case nightShiftDisableRuleDeactivated
    case nightShiftEnableRuleActivated
    case nightShiftEnableRuleDeactivated
    case scheduleChanged
}

enum DisableTimer: Equatable {
    case off
    case hour(timer: Timer, endDate: Date)
    case custom(timer: Timer, endDate: Date)
    
    static func == (lhs: DisableTimer, rhs: DisableTimer) -> Bool {
        switch (lhs, rhs) {
        case (.off, .off):
            return true
        case (let .hour(leftTimer, leftDate), let .hour(rightTimer, rightDate)),
             (let .custom(leftTimer, leftDate), let .custom(rightTimer, rightDate)):
            return leftTimer == rightTimer && leftDate == rightDate
        default:
            return false
        }
    }
}
