//
//  Location.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-10.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import UIKit
import CoreLocation


// We have provided a basic location service class to retrieve the user's location
// You can replace this with your own implementation to retrieve location

private let sharedService = LocationService()

class LocationService: NSObject, CLLocationManagerDelegate {
    
    class var shared: LocationService {
        return sharedService
    }
    
    var locationManager = CLLocationManager()
    
    var delegate: LocationServiceDelegate?
    
    override init() {
        super.init()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func startUpdatingHeading() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopUpdatingHeading() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.stopUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let delegate = self.delegate {
            delegate.updateLocationDidFailWithError(error: error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, let delegate = self.delegate {
            delegate.updateLocation(currentLocation: location, locationManager: manager)
        }
    }
    
    // Prompt user to change location settings if they have already declined permission
    // example of location request, copy paste into View Controller where user should be prompted
//    private func showLocationDisabledPopUp() {
//        let alertController = UIAlertController(title: "Location Access Disabled",
//                                                message: "We require your location to provide you with a custom navigation experience",
//                                                preferredStyle: .alert)
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        alertController.addAction(cancelAction)
//
//        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
//            if let url = URL(string: UIApplicationOpenSettingsURLString) {
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            }
//        }
//
//        alertController.addAction(openAction)
//
//        self.present(alertController, animated: true, completion: nil)
//    }
    
}

protocol LocationServiceDelegate {
    func updateLocation(currentLocation: CLLocation, locationManager: CLLocationManager)
    func updateLocationDidFailWithError(error: Error)
}
