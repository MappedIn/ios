//
//  MarkersVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class MarkersVC: UIViewController {
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
                                labelAllLocationsOnInit: false,
                                backgroundColor: "#ffffff"
                              ))
            
        }
    }
}

extension MarkersVC: MPIMapViewDelegate {
    func onDataLoaded(data: Mappedin.MPIData) {
        
    }
    
    func onFirstMapLoaded() {
        mapView?.flatLabelManager.labelAllLocations(options: MPIOptions.FlatLabelAllLocations())
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
        guard let location = polygon.locations?.first else { return }
        guard let entrance = polygon.entrances?.first else { return }
        
        mapView?.createMarker(node: entrance, contentHtml: "<div style=\"background-color:white; border: 2px solid black; padding: 0.4rem; border-radius: 0.4rem;\">\(location.name)</div>",
                              markerOptions: MPIOptions.Marker(rank: 4.0, anchor: MPIOptions.MARKER_ANCHOR.CENTER)
        )
        
    }
}
