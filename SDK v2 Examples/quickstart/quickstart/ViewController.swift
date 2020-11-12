//
//  ViewController.swift
//  quickstart
//
//  Created by Youel Kaisar on 2020-09-02.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import CoreLocation

class ViewController: UIViewController, MiMapViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a Mappedin object and enter your keys through the initializer
        // You can use these sample keys for now to access a few demo venues
        let mappedin = Mappedin(mappedinKey: "5f4e59bb91b055001a68e9d9", mappedinSecret: "gmwQbwuNv7cvDYggcYl4cMa5c7n0vh4vqNQEkoyLRuJ4vU42")

        // Set up the MapView, this is where you will render your maps
        let mapView = MiMapView(frame: view.bounds, styleURL: nil)
        view.addSubview(mapView)
        
        // Get the venue:
        // With the sample keys provided above, you have access to mappedin-demo-mall and a
        // few other demo venues. You can access the complete list with mappedin.getVenues()
        // For now we'll just load mappedin-demo-mall
        mappedin.getVenue(venueSlug: "mappedin-demo-mall") { (result, venue) in
            // The completionHandler closure is called once the venue has finished loading
            // The completion handler passes an MiGetVenueResultCode on whether or not the
            // venue data was retrieved
            if let venue = venue {
                // Load the venue into the mapView
                // This venue object contains all of the location, obstruction, space, category data
                mapView.loadMap(venue: venue)
            }
        }
    }

    func onTapNothing() {
    }

    func didTapSpace(space: MiSpace) -> Bool {
        return true
    }

    func onTapCoordinates(point: CLLocationCoordinate2D) {
    }

    func didTapOverlay(overlay: MiOverlay) -> Bool {
        return true
    }

    func onLevelChange(level: MiLevel) {
    }

    func onManipulateCamera(gesture: MiGestureType) {
    }

    func onMapLoaded(status: MiMapStatus) {
    }
}

