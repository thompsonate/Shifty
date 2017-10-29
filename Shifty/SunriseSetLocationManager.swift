//
//  SunriseSetLocationManager.swift
//  Shifty
//
//  Created by Nate Thompson on 9/30/17.
//

import Cocoa
import CoreLocation

class SunriseSetLocationManager: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var setSunTimes: ((Date, Date) -> Void)!
    var shouldShowLocationServicesDeniedAlert = true
    
    func setup() {
        locationManager.delegate = self
    }
    
    func updateLocationStatus() {
        switch BLClient.schedule {
        case .sunSchedule:
            locationManager.startMonitoringSignificantLocationChanges()
        default:
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        let latitude = lastLocation.coordinate.latitude
        let longitude = lastLocation.coordinate.longitude
        print(lastLocation)
        let lastKnownLocation = Location(latitude: latitude, longitude: longitude, saveDate: Date())
        UserDefaults.standard.set(try? PropertyListEncoder().encode(lastKnownLocation), forKey: Keys.lastKnownLocation)
        
        getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error);
        //Update sunrise and sunset times based on last known location
        if let data = UserDefaults.standard.value(forKey: Keys.lastKnownLocation) as? Data {
            if let lastKnownLocation = try? PropertyListDecoder().decode(Location.self, from: data) {
                getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: lastKnownLocation.latitude, longitude: lastKnownLocation.longitude)
                print(lastKnownLocation)
            }
        } else {
            showLocationErrorAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("Location Services Authorized")
            updateLocationStatus()
        case .denied:
            print("Location Services Denied")
            if BLClient.isSunSchedule {
                showLocationServicesDeniedAlert()
            }
        case .notDetermined:
            print("Location Services Not Determined")
            locationManager.startUpdatingLocation()
            locationManager.stopUpdatingLocation()
        case .restricted:
            print("Location Services Restricted")
            if BLClient.isSunSchedule {
                showLocationServicesDeniedAlert()
            }
        default: break
        }
    }
    
    var isAuthorizationDenied: Bool {
        return CLLocationManager.authorizationStatus() == .denied ||
            CLLocationManager.authorizationStatus() == .restricted
    }
    
    func getSunriseSetTimes(timeZone: TimeZone, latitude: Double, longitude: Double) {
        let sunTimes = EDSunriseSet(date: Date(), timezone: timeZone, latitude: latitude, longitude: longitude)
        setSunTimes(sunTimes.sunrise, sunTimes.sunset)
    }
    
    func showLocationServicesDeniedAlert() {
        let privacyPrefs = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")
        let alert = NSAlert()
        alert.messageText = "Location Services disabled"
        alert.informativeText = "Allow access to your location in order to use Shifty with the Sunset to Sunrise schedule. Shifty needs access to your location to calculate sunrise and sunset times."
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Open Preferences")
        alert.addButton(withTitle: "Turn schedule off")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(privacyPrefs!)
            shouldShowLocationServicesDeniedAlert = true
        } else {
            BLClient.setSchedule(.off)
            shouldShowLocationServicesDeniedAlert = true
        }
    }
    
    func showLocationErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Unable to get location"
        alert.informativeText = "Check your internet connection. Shifty needs access to your location to calculate sunrise and sunset times."
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Try again")
        alert.addButton(withTitle: "Turn schedule off")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            locationManager.stopMonitoringSignificantLocationChanges()
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            BLClient.setSchedule(.off)
        }
    }
}



class Location: NSObject, Codable {
    
    var lat: Double
    var long: Double
    var date: Date
    
    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, saveDate: Date) {
        self.lat = latitude
        self.long = longitude
        self.date = saveDate
    }
    
    public var latitude: Double {
        return lat
    }
    
    public var longitude: Double {
        return long
    }
    
    public var saveDate: Date {
        return date
    }
}



