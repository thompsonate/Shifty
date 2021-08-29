//
//  DateTime+Shifty.swift
//  DateTime+Shifty
//
//  Created by Nate Thompson on 8/28/21.
//

import Foundation

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

