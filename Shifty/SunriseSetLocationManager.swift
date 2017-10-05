//
//  SunriseSetLocationManager.swift
//  Shifty
//
//  Created by Nate Thompson on 9/30/17.
//

import Foundation
import CoreLocation

class SunriseSetLocationManager: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    func setup() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        let latitude = lastLocation.coordinate.latitude
        let longitude = lastLocation.coordinate.longitude
        let times = getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: latitude, longitude: longitude)
        print("sunrise: \(times.sunrise!) sunset: \(times.sunset!)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error);
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("Location Services Authorized")
            locationManager.startUpdatingLocation()
        case .denied:
            print("Location Services Denied")
            break
        case .notDetermined:
            print("Location Services Not Determined")
            locationManager.startUpdatingLocation()
            locationManager.stopUpdatingLocation()
            break
        case .restricted:
            print("Location Services Restricted")
            break
        default: break
        }
    }
    
    func getSunriseSetTimes(timeZone: TimeZone, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?) {
        let sunTimes = EDSunriseSet(date: Date(), timezone: timeZone, latitude: latitude, longitude: longitude)
        return (sunTimes?.sunrise, sunTimes?.sunset)
    }
    
}
