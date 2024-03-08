//
//  AddingInteractivityVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class AddingInteractivityVC: UIViewController, MPIMapClickDelegate, MPIMapViewDelegate {

    var mapView: MPIMapView?
    var loadingIndicator: UIActivityIndicatorView?

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
    
    func onClick(mapClickEvent: Mappedin.MPIMapClickEvent) {
        var message = ""
        
        // Use the map name as the title.
        let title = mapClickEvent.maps.first?.name ?? ""
        
        // If a floating label was clicked, add its text to the message.
        if (!mapClickEvent.floatingLabels.isEmpty)  {
            message.append("Floating Label Clicked: ")
            message.append(mapClickEvent.floatingLabels.first?.text ?? "")
            message.append("\n")
        }
        
        // If a polygon was clicked, add it's location name to the message.
        if (!mapClickEvent.polygons.isEmpty) {
            message.append("Polygon clicked: ")
            message.append(mapClickEvent.polygons.first?.locations?.first?.name ?? "")
            message.append("\n")
        }

        // If a path was clicked, add it to the message.
        if (!mapClickEvent.paths.isEmpty) {
            message.append("You clicked a path.\n")
        }
        
        // Add the coordinates clicked to the message.
        message.append("Coordinate Clicked: \nLatitude: ")
        message.append(mapClickEvent.position?.latitude.description ?? "")
        message.append("\nLongitude: ")
        message.append(mapClickEvent.position?.longitude.description ?? "")
        
        showMessage(title: title, message: message)
        
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
        
        // Make floating labels interactive.
        mapView?.floatingLabelManager.labelAllLocations(options: MPIOptions.FloatingLabelAllLocations(interactive: true))
        
        // Draw an interactive journey.
        var departure = mapView?.venueData?.locations.first(where: {$0.name == "Microsoft"} )
        var destination = mapView?.venueData?.locations.first(where: {$0.name == "Apple"} )
        
        if (departure == nil || destination == nil ) {return}
        
        let journeyOpt = MPIOptions.Journey(pathOptions: MPIOptions.Path(interactive: true))
        
        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            self.mapView?.journeyManager.draw(directions: directions!, options: journeyOpt)
        }
        
        //Draw an interactive path.
        departure = mapView?.venueData?.locations.first(where: {$0.name == "Uniqlo"} )
        destination = mapView?.venueData?.locations.first(where: {$0.name == "Nespresso"} )
        
        if (departure == nil || destination == nil ) {return}
        
        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            self.mapView?.pathManager.add(nodes: directions!.path, options: MPIOptions.Path(interactive: true))
        }
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
