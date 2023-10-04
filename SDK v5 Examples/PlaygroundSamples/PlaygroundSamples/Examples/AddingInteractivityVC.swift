//
//  AddingInteractivityVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class AddingInteractivityVC: UIViewController, MPIMapClickDelegate {

    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        mapView?.mapClickDelegate = self
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
    
    func onClick(mapClickEvent: Mappedin.MPIMapClickEvent) {
        mapView?.cameraManager.focusOn(targets: MPIOptions.CameraTargets(polygons: mapClickEvent.polygons))
    }
    
}
