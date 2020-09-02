//
//  ViewController.swift
//  quickstart
//
//  Created by Youel Kaisar on 2020-09-02.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a Mappedin object and enter your keys through the initializer
        let mappedIn = Mappedin(mappedinKey: "5f2c5b9aa5fdf5001a6b971d", mappedinSecret: "tsKYDtd9xnks2WNu9YHS5SrfHwwENGeHnaAyMTI5jPhpsEbU")
        
        let mapView = MiMapView(frame: view.bounds, styleURL: nil)
        view.addSubview(mapView)
        
        // get the venue
        // The completionHandler closure is called once the venue has finished loading
        // The completion handler passes an MiGetVenueResultCode on whether or not the venue data was retrieved
        mappedIn.getVenue(venueSlug: "mappedin-demo-mall") { (result, venue) in
            // This venue object contains all of the location, obstruction, space, category data required to display the map
            if let venue = venue {
                // With this venue object, you can now load it into the map as seen below:
                mapView.loadMap(venue: venue)
            }
        }
    }
}

