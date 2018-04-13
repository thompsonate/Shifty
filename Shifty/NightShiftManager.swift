//
//  NightShiftManager.swift
//  Shifty
//
//  Created by Saagar Jha on 1/13/18.
//

import Cocoa
import SwiftLog

let BSClient = BrightnessSystemClient()

extension Time: Equatable, Comparable {
    init(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
            let minute = components.minute else {
                fatalError("Could not instantiate Time object")
        }
        self.init()
        self.hour = Int32(hour)
        self.minute = Int32(minute)
    }
    
    static var now: Time {
        return Time(Date())
    }
    
    public static func ==(lhs: Time, rhs: Time) -> Bool {
        return lhs.hour == rhs.hour && lhs.minute == rhs.minute
    }
    
    public static func < (lhs: Time, rhs: Time) -> Bool {
        if lhs.hour == rhs.hour {
            return lhs.minute < rhs.minute
        } else {
            return lhs.hour < rhs.hour
        }
    }
}

extension Date {
    init(_ time: Time) {
        var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        components.hour = Int(time.hour)
        components.minute = Int(time.minute)
        if let date = Calendar.current.date(from: components) {
            self = date
        } else {
            fatalError("Could not instantiate Date object")
        }
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
}

enum DisableTimer: Equatable {
    case off
    case hour(timer: Timer)
    case custom(timer: Timer)
    
    static func == (lhs: DisableTimer, rhs: DisableTimer) -> Bool {
        switch (lhs, rhs) {
        case (.off, .off):
            return true
        case (let .hour(leftTimer), let .hour(rightTimer)), (let .custom(leftTimer), let .custom(rightTimer)):
            return leftTimer == rightTimer
        default:
            return false
        }
    }
}

enum ScheduleType: Equatable {
    case off
    case solar
    case custom(start: Time, end: Time)
    
    static func == (lhs: ScheduleType, rhs: ScheduleType) -> Bool {
        switch (lhs, rhs) {
        case (.off, .off), (.solar, .solar):
            return true
        case (let .custom(leftStart, leftEnd), let custom(rightStart, rightEnd)):
            return leftStart == rightStart && leftEnd == rightEnd
        default:
            return false
        }
    }
}

enum NightShiftManager {
    private static let client = CBBlueLightClient()

    static var isCurrentlyInNightShiftSchedule: Bool = false
    static var userSet: Bool? = false
 
    private static var blueLightStatus: Status {
        var status: Status = Status()
        client.getBlueLightStatus(&status)
        return status
    }

    static var blueLightReductionAmount: Float {
        get {
            var strength: Float = 0
            client.getStrength(&strength)
            return strength
        }
        set {
            client.setStrength(newValue, commit: true)
        }
    }

    static var isNightShiftEnabled: Bool {
        get {
            return blueLightStatus.enabled.boolValue
        }
        set {
            client.setEnabled(newValue)
        }
    }

    static var supportsNightShift: Bool {
        get {
            return CBBlueLightClient.supportsBlueLightReduction()
        }
    }

    static var schedule: ScheduleType {
        get {
            switch blueLightStatus.mode {
            case 0:
                return .off
            case 1:
                return .solar
            case 2:
                return .custom(start: blueLightStatus.schedule.fromTime, end: blueLightStatus.schedule.toTime)
            default:
                assertionFailure("Unknown mode")
                return .off
            }
        }
        set {
            switch newValue {
            case .off:
                client.setMode(0)
            case .solar:
                client.setMode(1)
            case .custom(start: let start, end: let end):
                client.setMode(2)
                var schedule = Schedule(fromTime: start, toTime: end)
                client.setSchedule(&schedule)
            }
        }
    }
    
    static var scheduledState: Bool {
        switch schedule {
        case .off:
            return false
        case .custom(start: let startTime, end: let endTime):
            let now = Time(Date())
            if endTime > startTime {
                //startTime and endTime are on the same day
                return now > startTime && now < endTime
            } else {
                //endTime is on the day following startTime
                return now > startTime || now < endTime
            }
        case .solar:
            guard let isDaylight = BSClient?.isDaylight else { return false }
            //Should be false between sunrise and sunset
            return !isDaylight
        }
    }
    
    public static func setToSchedule() {
        switch schedule {
        case .off:
            isNightShiftEnabled = false
        case .custom(start: let startTime, end: let endTime):
            schedule = .off
            schedule = .custom(start: startTime, end: endTime)
        case .solar:
            schedule = .off
            schedule = .solar
        }
    }
    
    private static var userOverridden: Bool?
    
    static var nightShiftDisableTimer = DisableTimer.off {
        willSet {
            switch nightShiftDisableTimer {
            case .hour(let timer), .custom(let timer):
                timer.invalidate()
            default: break
            }
        }
    }
    
    static var disabledTimer: Bool {
        return NightShiftManager.nightShiftDisableTimer != .off
    }
    
    private static var disableRuleIsActive: Bool {
        return RuleManager.disableRuleIsActive
    }

    public static func initialize() {
        NightShiftManager.isCurrentlyInNightShiftSchedule = false
        // @convention block
        client.setStatusNotificationBlock {
            respond(to: isNightShiftEnabled ? .enteredScheduledNightShift : .exitedScheduledNightShift)
            
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.updateMenuBarIcon()
            
            let prefWindow = (NSApplication.shared.delegate as? AppDelegate)?.preferenceWindowController
            let prefGeneral = prefWindow?.viewControllers.compactMap { childViewController in
                return childViewController as? PrefGeneralViewController
                }.first
            DispatchQueue.main.async {
                prefGeneral?.updateSchedule?()
            }
            
            updateDarkMode()
        }
    }
    
    static func updateDarkMode() {
        if UserDefaults.standard.bool(forKey: Keys.isDarkModeSyncEnabled) {
            switch schedule {
            case .off:
                let darkModeState = isNightShiftEnabled || disableRuleIsActive || disabledTimer || userOverridden == false
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

    static func respond(to event: NightShiftEvent) {
        switch event {
        case .enteredScheduledNightShift:
            userOverridden = nil
            if disabledTimer || disableRuleIsActive {
                isNightShiftEnabled = false
            }
        case .exitedScheduledNightShift:
            userOverridden = nil
        case .userEnabledNightShift:
            userOverridden = true
            nightShiftDisableTimer = .off
            
            if disableRuleIsActive {
                RuleManager.removeRulesForCurrentState()
            }
            isNightShiftEnabled = true
        case .userDisabledNightShift:
            isNightShiftEnabled = false
            userOverridden = false
        case .nightShiftDisableRuleActivated:
            userOverridden = nil
            isNightShiftEnabled = false
        case .nightShiftDisableRuleDeactivated:
            userOverridden = nil
            if !disabledTimer && !disableRuleIsActive {
                setToSchedule()
            }
        case .nightShiftEnableRuleActivated:
            isNightShiftEnabled = true
        case .nightShiftEnableRuleDeactivated:
            if disabledTimer || disableRuleIsActive {
                isNightShiftEnabled = false
            } else {
                setToSchedule()
            }
        case .nightShiftDisableTimerStarted:
            userOverridden = nil
            isNightShiftEnabled = false
        case .nightShiftDisableTimerEnded:
            userOverridden = nil
            nightShiftDisableTimer = .off
            if !disableRuleIsActive {
                setToSchedule()
            }
        }
    }
}
