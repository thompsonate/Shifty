//
//  IntentHandlers.swift
//  IntentHandlers
//
//  Created by Nate Thompson on 8/28/21.
//

import Foundation
import Intents

@available(macOS 12.0, *)
class GetNightShiftStateIntentHandler: NSObject, GetNightShiftStateIntentHandling {
    func handle(intent: GetNightShiftStateIntent) async -> GetNightShiftStateIntentResponse {
        let response = GetNightShiftStateIntentResponse(code: .success, userActivity: nil)
        response.nightShiftState = NightShiftManager.isNightShiftEnabled as NSNumber
        return response
    }
}

@available(macOS 12.0, *)
class SetNightShiftStateIntentHandler: NSObject, SetNightShiftStateIntentHandling {
    func handle(intent: SetNightShiftStateIntent) async -> SetNightShiftStateIntentResponse {
        let state = intent.nightShiftState!.boolValue
        NightShiftManager.setNightShiftEnabled(to: state)
        return SetNightShiftStateIntentResponse(code: .success, userActivity: nil)
    }

    func resolveNightShiftState(for intent: SetNightShiftStateIntent) async -> INBooleanResolutionResult {
        guard let state = intent.nightShiftState?.boolValue else {
            return .needsValue()
        }
        return .success(with: state)
    }
}

@available(macOS 12.0, *)
class GetColorTemperatureIntentHandler: NSObject, GetColorTemperatureIntentHandling {
    func handle(intent: GetColorTemperatureIntent) async -> GetColorTemperatureIntentResponse {
        let response = GetColorTemperatureIntentResponse(code: .success, userActivity: nil)
        
        if NightShiftManager.isNightShiftEnabled {
            response.colorTemperature = NightShiftManager.blueLightReductionAmount as NSNumber
        } else {
            response.colorTemperature = 0
        }
        return response
    }
}

@available(macOS 12.0, *)
class SetColorTemperatureIntentHandler: NSObject, SetColorTemperatureIntentHandling {
    func handle(intent: SetColorTemperatureIntent) async -> SetColorTemperatureIntentResponse {
        let colorTemp = intent.colorTemperature!.floatValue
        NightShiftManager.setNightShiftEnabled(to: colorTemp > 0)
        NightShiftManager.blueLightReductionAmount = colorTemp
        return SetColorTemperatureIntentResponse(code: .success, userActivity: nil)
    }
    
    func resolveColorTemperature(for intent: SetColorTemperatureIntent) async -> SetColorTemperatureColorTemperatureResolutionResult {
        guard let colorTemperature = intent.colorTemperature?.doubleValue else {
            return .needsValue()
        }
        return .success(with: colorTemperature)
    }
}

@available(macOS 12.0, *)
class SetDisableTimerIntentHandler: NSObject, SetDisableTimerIntentHandling {
    func handle(intent: SetDisableTimerIntent) async -> SetDisableTimerIntentResponse {
        let durationInSeconds = intent.duration!.intValue
        // TODO: handle timer
        return SetDisableTimerIntentResponse(code: .success, userActivity: nil)
    }

    func resolveDuration(for intent: SetDisableTimerIntent) async -> INTimeIntervalResolutionResult {
        guard let duration = intent.duration?.doubleValue else {
            return .needsValue()
        }
        return .success(with: duration)
    }
}

@available(macOS 12.0, *)
class GetTrueToneStateIntentHandler: NSObject, GetTrueToneStateIntentHandling {
    func handle(intent: GetTrueToneStateIntent) async -> GetTrueToneStateIntentResponse {
        switch CBTrueToneClient.shared.state {
        case .unsupported:
            return GetTrueToneStateIntentResponse(code: .trueToneNotSupported, userActivity: nil)
        case .unavailable:
            return GetTrueToneStateIntentResponse(code: .trueToneNotAvailable, userActivity: nil)
        case .enabled, .disabled:
            let response = GetTrueToneStateIntentResponse(code: .success, userActivity: nil)
            response.trueToneState = CBTrueToneClient.shared.isTrueToneEnabled as NSNumber
            return response
        }
    }
}

@available(macOS 12.0, *)
class SetTrueToneStateIntentHandler: NSObject, SetTrueToneStateIntentHandling {
    func handle(intent: SetTrueToneStateIntent) async -> SetTrueToneStateIntentResponse {
        if CBTrueToneClient.shared.isTrueToneSupported == false {
            return SetTrueToneStateIntentResponse(code: .trueToneNotSupported, userActivity: nil)
        }
        if CBTrueToneClient.shared.isTrueToneAvailable == false {
            return SetTrueToneStateIntentResponse(code: .trueToneNotAvailable, userActivity: nil)
        }
        CBTrueToneClient.shared.isTrueToneEnabled = intent.trueToneState!.boolValue
        return SetTrueToneStateIntentResponse(code: .success, userActivity: nil)
    }
    
    func resolveTrueToneState(for intent: SetTrueToneStateIntent) async -> INBooleanResolutionResult {
        guard let state = intent.trueToneState?.boolValue else  {
            return .needsValue()
        }
        return .success(with: state)
    }
}
