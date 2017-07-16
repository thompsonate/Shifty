//
//  CBBlueLightClient+Shifty.swift
//  Shifty
//
//  Created by Nate Thompson on 7/14/17.
//
//

import Foundation

typealias Time = (hour: Int, minute: Int)

enum ScheduleType {
    case off
    case sunSchedule
    case timedSchedule(startTime: Date, endTime: Date)
}

extension CBBlueLightClient {
    var strength: Float {
        var strength: Float = 0.0
        self.getStrength(&strength)
        return strength
    }
    
    var CCT: Float {
        var CCT: Float = 0.0
        self.getCCT(&CCT)
        return CCT
    }
    
    var isNightShiftEnabled: Bool {
        return getBoolFromBlueLightStatus(index: 1)
    }
    
    var schedule: ScheduleType {
        switch(getIntFromBlueLightStatus(index: 4)) {
        case 0:
            return .off
        case 1:
            return .sunSchedule
        case 2:
            let calendar = NSCalendar(identifier: .gregorian)!
            
            var startComponents = DateComponents()
            startComponents.hour = getIntFromBlueLightStatus(index: 8)
            startComponents.minute = getIntFromBlueLightStatus(index: 12)
            let startDate = calendar.date(from: startComponents)
            
            var endComponents = DateComponents()
            endComponents.hour = getIntFromBlueLightStatus(index: 16)
            endComponents.minute = getIntFromBlueLightStatus(index: 20)
            let endDate = calendar.date(from: endComponents)
            
            if let startDate = startDate, let endDate = endDate {
                return .timedSchedule(startTime: startDate, endTime: endDate)
            } else {
                return .off
            }
            
        default:
            return .off
        }
    }
    
    func getIntFromBlueLightStatus(index: Int) -> Int {
        //create an empty mutable OpaquePointer
        let string = "000000000000000000000000000000"
        var data = string.data(using: .utf8)!
        let ints: UnsafeMutablePointer<Int>! = data.withUnsafeMutableBytes{ $0 }
        let bytes = OpaquePointer(ints)
        
        //load the BlueLightStatus struct into the opaque pointer
        self.getBlueLightStatus(bytes)
        
        //get the byes from the BlueLightStatus pointer
        let intsArray = [UInt8](data)
        
        //passes in index parameter
        return Int(intsArray[index])
    }
    
    func getBoolFromBlueLightStatus(index: Int) -> Bool {
        return getIntFromBlueLightStatus(index: index) == 1
    }
}


