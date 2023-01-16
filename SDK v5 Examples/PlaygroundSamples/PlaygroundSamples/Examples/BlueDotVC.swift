//
//  BlueDotVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class BlueDotVC: UIViewController {
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ))
        }
    }
}

extension BlueDotVC: MPIMapViewDelegate {
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        mapView?.blueDotManager.enable(options: MPIOptions.BlueDot(smoothing: false, showBearing: true))
        let coords = MPICoordinates(latitude: 43.52012478635707, longitude: -80.53951744629536, accuracy: 2.0, floorLevel: 0)
        let position = MPIPosition(timestamp: 1.0, coords: coords)
        mapView?.blueDotManager.updatePosition(position: position)
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
