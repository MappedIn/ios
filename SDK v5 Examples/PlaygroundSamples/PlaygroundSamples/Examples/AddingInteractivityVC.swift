//
//  AddingInteractivityVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class AddingInteractivityVC: UIViewController, MPIMapClickDelegate, MPIMapViewDelegate {

    

    var mapView: MPIMapView?
    var mapView2: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height

        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight / 2))
        mapView2 = MPIMapView(frame: CGRect(x: 0, y: screenHeight / 2, width: screenWidth, height: screenHeight / 2))
        
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
                    venue: "mappedin-demo-mall"
                )){ error in
                    print(error.debugDescription)
                }
        }
        
        if let mapView2 = mapView2 {
            view.addSubview(mapView2)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView2.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                )){ error in
                    print(error.debugDescription)
                }
        }
    }
    
    func onClick(mapClickEvent: Mappedin.MPIMapClickEvent) {
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-stadium"
                )){ error in
                    print(error.debugDescription)
                }
        }
        
        if let mapView2 = mapView2 {
            view.addSubview(mapView2)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView2.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-stadium"
                )){ error in
                    print(error.debugDescription)
                }
        }
        
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
