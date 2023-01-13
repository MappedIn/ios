//
//  AddingInteractivityVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class AddingInteractivityVC: UIViewController {
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
        if let mapView = mapView {
            self.view.addSubview(mapView)
            
            mapView.loadVenue(options:
                                MPIOptions.Init(
                                    clientId: "5eab30aa91b055001a68e996",
                                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                                    venue: "mappedin-demo-mall"
                                ),
                              showVenueOptions: MPIOptions.ShowVenue(
                                backgroundColor: "#ffffff"
                              ))
        }
    }
}

extension AddingInteractivityVC: MPIMapViewDelegate {
    func onDataLoaded(data: Mappedin.MPIData) {
        
    }
    
    func onFirstMapLoaded() {
        
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {
        
    }
    
    func onNothingClicked() {
        
    }
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {
        
    }
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {
        
    }
    
    func onStateChanged(state: Mappedin.MPIState) {
        
    }
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {
        
    }
    
    func onPolygonClicked(polygon: MPIPolygon) {
        mapView?.clearAllPolygonColors() { error in
            self.mapView?.setPolygonColor(polygon: polygon, color: "#BF4320")
        }
    }
}
