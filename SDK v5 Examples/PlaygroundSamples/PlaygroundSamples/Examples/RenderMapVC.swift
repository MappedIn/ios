//
//  RenderMapVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class RenderMapVC: UIViewController, MPIMapViewDelegate {
    var mapView: MPIMapView?
    
    
    let venues = ["mappedin-demo-mall", "mappedin-demo-office", "mappedin-demo-stadium"]
    var venueCount = 0
    
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
                )){ error in
                    print("Load \(self.venueCount)")
                    print(error.debugDescription)
                }
        }
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {
        venueCount = venueCount + 1
        
        if (venueCount < 3) {
            if let mapView = mapView {
                view.addSubview(mapView)
                
                // See Trial API key Terms and Conditions
                // https://developer.mappedin.com/api-keys/
                mapView.loadVenue(options:
                    MPIOptions.Init(
                        clientId: "5eab30aa91b055001a68e996",
                        clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                        venue: venues[venueCount]
                    )){ error in
                        print("Load \(self.venueCount)")
                        print(error.debugDescription)
                    }
            }
        }
        
    }
    
    func onFirstMapLoaded() {

    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
}
