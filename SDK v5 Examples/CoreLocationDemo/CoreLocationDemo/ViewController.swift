//
//  ViewController.swift
//  CoreLocationDemo
//

import UIKit
import Mappedin
import CoreLocation

class ViewController: UIViewController, MPIMapViewDelegate, CLLocationManagerDelegate  {
    var mapView: MPIMapView?
    var locationManager: CLLocationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up CLLocationManager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        // Set up MPIMapView and add to view
        mapView = MPIMapView(frame: view.frame)
        if let mapView = mapView {
            self.view.addSubview(mapView)
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall")
            )
        }
        mapView?.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            print("Authorized when in use")
            manager.startUpdatingLocation()
            break
        case .restricted, .denied:
            print("Denied")
            break
        case .notDetermined:
            print("Not determined")
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Get most recent location
        guard let location = locations.first else { return }
        let coords = MPICoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy, floorLevel: 0)
        // Update Blue Dot
        mapView?.blueDotManager.updatePosition(position: MPIPosition(coords: coords))
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        // Enable Blue Dot on load
        mapView?.blueDotManager.enable(options: MPIOptions.BlueDot(smoothing: false))
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
}

