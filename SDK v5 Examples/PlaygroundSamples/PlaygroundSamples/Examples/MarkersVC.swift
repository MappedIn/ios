//
//  MarkersVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class MarkersVC: UIViewController, MPIMapViewDelegate, MPIMapClickDelegate {
    
    var mapView: MPIMapView?
    var markerIds: [String] = .init()
    var loadingIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
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
                ),
                  showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: false, multiBufferRendering: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
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
        
        mapView?.flatLabelManager.labelAllLocations(options: MPIOptions.FlatLabelAllLocations())
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
    
    func onClick(mapClickEvent: Mappedin.MPIMapClickEvent) {
        if (mapClickEvent.polygons.isEmpty) {
            //Remove all markers.
            for markerId in markerIds {
                mapView?.removeMarker(id: markerId)
            }
            
        } else {
            //Add a marker to the polygon clicked on.
            guard let location = mapClickEvent.polygons.first?.locations?.first else { return }
            guard let entrance = mapClickEvent.polygons.first?.entrances?.first else { return }
            
            if let markerId = mapView?.createMarker(
                node: entrance,
                contentHtml: """
                <div style=\"background-color:white; border: 2px solid black; padding: 0.4rem; border-radius: 0.4rem;\">
                \(location.name)
                </div>
                """,
                markerOptions: MPIOptions.Marker(rank: MPIOptions.CollisionRankingTiers.medium, anchor: MPIOptions.MARKER_ANCHOR.CENTER)
            ) {
                markerIds.append(markerId)
            }
        }
    }
}
