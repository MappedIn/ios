//
//  TooltipsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class TooltipsVC: UIViewController, MPIMapViewDelegate, MPIMapClickDelegate {
    
    var mapView: MPIMapView?
    var tooltipIds: [String] = .init()
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
                  showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: false, multiBufferRendering: true, xRayPath: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
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
        
        let departure = mapView?.venueData?.locations.first(where: { $0.name == "Cleo" })
        let destination = mapView?.venueData?.locations.first(where: { $0.name == "Pandora" })

        guard departure != nil && destination != nil else { return }

        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            // Draw a path using Path Manager.
            self.mapView?.pathManager.add(nodes: directions!.path)
            directions?.instructions.forEach{instruction in
                if (instruction.node != nil)
                {
                    self.mapView?.createTooltip(
                        node: instruction.node!,
                        contentHtml: """
                    <span style="background-color: azure; padding:0.2rem; font-size:0.7rem">
                    \(instruction.instruction ?? "")
                    </span>
                    """,
                        tooltipOptions: MPIOptions.Tooltip(collisionRank: MPIOptions.CollisionRankingTiers.medium)) {
                            id in
                            print ("Tooltip added with id: " + (id ?? ""));
                        }
                }
            }
            // Focus the camera on the path.
            let targets = MPIOptions.CameraTargets(nodes: directions?.path)
            self.mapView?.cameraManager.focusOn(targets: targets, options: MPIOptions.FocusOnOptions(minZoom: 1800.0))
        }
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
            //Remove all tooltips.
            for tooltipId in tooltipIds {
                mapView?.removeTooltip(tooltipId: tooltipId)
            }
        } else {
            //Add a tooltip to the polygon clicked on.
            guard let location = mapClickEvent.polygons.first?.locations?.first else { return }
            guard let entrance = mapClickEvent.polygons.first?.entrances?.first else { return }
            
            mapView?.createTooltip(
                node: entrance,
                contentHtml: """
                <div style=\"background-color:white; border: 2px solid black; padding: 0.4rem; border-radius: 0.4rem;\">
                \(location.name)
                </div>
                """,
                tooltipOptions: MPIOptions.Tooltip(collisionRank: MPIOptions.CollisionRankingTiers.medium)) {
                    id in
                    if (id != nil) {
                        self.tooltipIds.append(id!)
                    }
                }
        }
    }
}
