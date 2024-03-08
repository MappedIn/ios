//
//  ABWayfindingVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class ABWayfindingVC: UIViewController, MPIMapViewDelegate {

    var mapView: MPIMapView?
    var loadingIndicator: UIActivityIndicatorView?

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
                ),
                  showVenueOptions: MPIOptions.ShowVenue(multiBufferRendering: true, xRayPath: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
        }
        
        loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
        }
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
        
        var departure = mapView?.venueData?.locations.first(where: { $0.name == "Uniqlo" })
        var destination = mapView?.venueData?.locations.first(where: { $0.name == "Foot Locker" })

        guard departure != nil && destination != nil else { return }

        // Draw a path using Journey Manager.
        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            self.mapView?.journeyManager.draw(directions: directions!)
        }
        
        departure = mapView?.venueData?.locations.first { $0.name == "Apple" }
        destination = mapView?.venueData?.locations.first { $0.name == "Microsoft" }

        guard departure != nil && destination != nil else { return }
        
        // Draw a path using Path Manager.
        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            self.mapView?.pathManager.add(nodes: directions!.path, options: MPIOptions.Path(drawDuration: 2000.0))
        }
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
