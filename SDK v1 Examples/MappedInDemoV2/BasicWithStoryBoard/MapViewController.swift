//
//  MapViewController.swift
//  mapBox-Test
//
//  Created by Youel Kaisar on 2020-08-27
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mapbox
import Mappedin

class MapViewController: UIViewController{
    
    var venue:MiVenue!

    var mapView: MiMapView!

    @IBOutlet weak var levelUp: UIButton!
    @IBOutlet weak var levelDown: UIButton!
    
    @IBAction func didTapLevelUp(_ sender: UIButton) {
        incrementLevel()
    }

    @IBAction func didTapLevelDown(_ sender: UIButton) {
        decrementLevel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a Mappedin object and enter your keys through the property list file or the initializer
        let mappedIn = Mappedin()
        
        // Initialize an MiMapView object with the viewport bounds to contain the map
        // and the Mapbox style URL, if any.
        mapView = MiMapView(frame: view.bounds, styleURL: nil)
        
        // Sets the MiMapViewDelegate
        mapView.miDelegate = self

        // Add the MiMapView as a subview of the controller's view.
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        
        // Use the retrieved venue
        mappedIn.getVenue(venueSlug: "mappedin-demo-mall", completionHandler: {(resultCode, venue) -> Void in
            if resultCode == MIGetVenueResultCode.SUCCESS {
                // This venue object contains all of the location, obstruction, space, category data required to display the map
                if let venue = venue {
                    self.venue = venue
                    
                    // With this venue object, you can now load it into the map as seen below:
                    self.mapView.loadMap(venue: venue)
                }
            }
            
        })
    }

    func incrementLevel() {
        if mapView.canIncrementLevel() {
            mapView.incrementLevel()
        }
    }

    func decrementLevel() {
        if mapView.canDecrementLevel() {
            mapView.decrementLevel()
        }
    }
}

extension MapViewController: MiMapViewDelegate {
    func onTapNothing() {
        // Called when a tap doesn't hit any spaces
    }
    
    func didTapSpace(space: MiSpace) -> Bool {
        // Called when a space is tapped and provides which space was tapped
        // Return true to stop the tap
        // Return false to allow the tap to fall through and trigger other events
        return false
    }
    
    func onTapCoordinates(point: CLLocationCoordinate2D) {
        // Called when the map is tapped and provides the coordinates of the tap
    }
    
    func didTapOverlay(overlay: MiOverlay) -> Bool {
        // Called when an overlay is tapped and provides which overlay was tapped
        // Return true to stop the tap
        // Return false to allow the tap to fall through and trigger other events
        return false
    }
    
    func onLevelChange(level: MiLevel) {
        // Called when the level is changed and provides the new level
    }
    
    func onManipulateCamera(gesture: MiGestureType) {
        // Called when the user manipulates the camera
    }
    
    
    func onMapLoaded(status: MiMapStatus) {
        // Called when the `MiMapView` has finished loading both the view and the venue data
        
        // Makes the mapView focus on the current levels coordinates
        self.mapView.focusOnCurrentLevel()
    }
}
