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
    var setSunTimes: ((Date, Date) -> Void)!
    
    func setup() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        let latitude = lastLocation.coordinate.latitude
        let longitude = lastLocation.coordinate.longitude
        getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: latitude, longitude: longitude)
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
        case .notDetermined:
            print("Location Services Not Determined")
            locationManager.startUpdatingLocation()
            locationManager.stopUpdatingLocation()
        case .restricted:
            print("Location Services Restricted")
        default: break
        }
    }
    
    func getSunriseSetTimes(timeZone: TimeZone, latitude: Double, longitude: Double) {
        let sunTimes = EDSunriseSet(date: Date(), timezone: timeZone, latitude: latitude, longitude: longitude)
        setSunTimes(sunTimes.sunrise, sunTimes.sunset)
    }
    
}
