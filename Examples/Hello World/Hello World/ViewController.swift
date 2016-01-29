//
//  ViewController.swift
//  Hello World
//
//  Created by Paul Bernhardt on 2016-01-29.
//  Copyright © 2016 MappedIn. All rights reserved.
//

import UIKit
import MappedIn

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MapView!
    var venue = [Venue]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MappedIn.getVenues(loadFirstVenue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Functions
    func loadFirstVenue(venues: [Venue]) {
        if let venue: Venue = venues.first {
            MappedIn.getVenue(venue, callback: displayVenue)
        } else {
            print("No venues found. Make sure you set your MappedInUsername and MappedInPassword in your info.plist. If you did, talk to your MappedIn representative to ensure your key has access to a venue");
        }
    }
    
    func displayVenue(venue: Venue) {
        print("Venue got")
        mapView.venue = venue
        mapView.loadScene()
    }

}

