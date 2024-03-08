//
//  BlueDotVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class BlueDotVC: UIViewController, MPIMapViewDelegate {

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
                  showVenueOptions: MPIOptions.ShowVenue(multiBufferRendering: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
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
        
        mapView?.blueDotManager.enable(options: MPIOptions.BlueDot(smoothing: false, showBearing: true))
        
        // Load positions from blue-dot-positions.json
        guard let filepath = Bundle.main.path(forResource: "blue-dot-positions", ofType: "json") else { return }
        let contents = try? String(contentsOfFile: filepath)
        guard let positionData = contents?.data(using: .utf8) else { return }
        guard let positions = try? JSONDecoder().decode([MPIPosition].self, from: positionData) else {
            print("FAILED TO PARSE POSITIONS")
            return
        }
        
        mapView?.blueDotManager.setState(state: MPIState.FOLLOW)
        mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: 700))
        
        for (index, position) in positions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (3 * Double(index))) {
                self.mapView?.blueDotManager.updatePosition(position: position)
            }
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
