//
//  AddingInteractivityVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class AddingInteractivityVC: UIViewController, MPIMapClickDelegate, MPIMapViewDelegate {

    let venues = ["mappedin-demo-mall", "mappedin-demo-office", "mappedin-demo-stadium"]

    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        mapView?.mapClickDelegate = self
        mapView?.delegate = self
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: venues[0]
                )){ error in
                    print("Load #1")
                    print(error.debugDescription)
                }
        }
        
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: venues[1]
                )){ error in
                    print("Load #2")
                    print(error.debugDescription)
                }
        }
        
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: venues[2]
                )){ error in
                    print("Load #3")
                    print(error.debugDescription)
                }
        }
    }
    
    func onClick(mapClickEvent: Mappedin.MPIMapClickEvent) {
                
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {

    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
