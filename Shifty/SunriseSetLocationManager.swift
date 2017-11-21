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
    var shouldShowAlert = true
    
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    
    func setup() {
        locationManager.delegate = self
    }
    
    var sunTimes: (sunrise: Date, sunset: Date)? {
        if let latitude = latitude, let longitude = longitude {
            return getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: latitude, longitude: longitude)
        } else {
            if let data = UserDefaults.standard.value(forKey: Keys.lastKnownLocation) as? Data {
                if let lastKnownLocation = try? PropertyListDecoder().decode(Location.self, from: data) {
                    return getSunriseSetTimes(timeZone: NSTimeZone.system, latitude: lastKnownLocation.latitude, longitude: lastKnownLocation.longitude)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    func getSunriseSetTimes(timeZone: TimeZone, latitude: Double, longitude: Double) -> (sunrise: Date, sunset: Date) {
        let sunriseSet = EDSunriseSet(date: Date(), timezone: timeZone, latitude: latitude, longitude: longitude)
        return (sunriseSet.sunrise, sunriseSet.sunset)
    }
    
    func updateLocationMonitoringStatus() {
        switch BLClient.schedule {
        case .sunSchedule:
            locationManager.startMonitoringSignificantLocationChanges()
        default:
            locationManager.stopMonitoringSignificantLocationChanges()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        latitude = lastLocation.coordinate.latitude
        longitude = lastLocation.coordinate.longitude
        print(lastLocation)
        if let latitude = latitude, let longitude = longitude {
            let lastKnownLocation = Location(latitude: latitude, longitude: longitude, saveDate: Date())
            UserDefaults.standard.set(try? PropertyListEncoder().encode(lastKnownLocation), forKey: Keys.lastKnownLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error);
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("Location Services Authorized")
            updateLocationMonitoringStatus()
            if SSLocationManager.isAuthorized && BLClient.isSunSchedule && SSLocationManager.sunTimes == nil {
                SSLocationManager.showLocationErrorAlert()
                SSLocationManager.shouldShowAlert = false
            }
        case .denied:
            print("Location Services Denied")
            if BLClient.isSunSchedule {
                showLocationServicesDeniedAlert()
            }
        case .notDetermined:
            print("Location Services Not Determined")
            if BLClient.isSunSchedule {
                locationManager.startUpdatingLocation()
                locationManager.stopUpdatingLocation()
            }
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
    
    var isAuthorized: Bool {
        return CLLocationManager.authorizationStatus() == .authorized
    }
    
    func showLocationServicesDeniedAlert() {
        DispatchQueue.main.async {
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
                self.shouldShowAlert = true
            } else {
                BLClient.setSchedule(.off)
                self.shouldShowAlert = true
            }
            Event.locationServicesDeniedAlertShown.record()
        }
    }
    
    func showLocationErrorAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Unable to get location"
            alert.informativeText = "Check your internet connection. Shifty needs access to your location to calculate sunrise and sunset times."
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "Try again")
            alert.addButton(withTitle: "Turn schedule off")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.locationManager.stopMonitoringSignificantLocationChanges()
                self.locationManager.startMonitoringSignificantLocationChanges()
                if self.sunTimes == nil {
                    self.getLocationFromIP()
                }
                self.shouldShowAlert = true
            } else {
                BLClient.setSchedule(.off)
                self.shouldShowAlert = true
            }
            Event.locationErrorAlertShown.record()
        }
    }
    
    func getLocationFromIP() {
        let url = URL(string: "http://ip-api.com/json")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print(error?.localizedDescription as Any)
                self.showLocationErrorAlert()
                return
            }
            
            let jsonDecoder = JSONDecoder()
            if let location = try? jsonDecoder.decode(IpLocation.self, from: data) {
                let latitude = location.lat
                let longitude = location.lon
                let lastKnownLocation = Location(latitude: latitude, longitude: longitude, saveDate: Date())
                UserDefaults.standard.set(try? PropertyListEncoder().encode(lastKnownLocation), forKey: Keys.lastKnownLocation)
            } else {
                self.showLocationErrorAlert()
            }
        }
        task.resume()
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


struct IpLocation: Codable {
    let lat: Double
    let lon: Double
}


