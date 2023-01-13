//
//  RenderMapVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class RenderMapVC: UIViewController {
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        if let mapView = mapView {
            self.view.addSubview(mapView)

            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ),
                showVenueOptions: MPIOptions.ShowVenue(
                    labelAllLocationsOnInit: true,
                    backgroundColor: "#ffffff"
                ))
        }
    }
}
