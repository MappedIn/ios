//
//  ViewController.swift
//  Hello World
//
//  Created by Paul Bernhardt on 2016-01-29.
//  Copyright © 2016 MappedIn. All rights reserved.
//

import UIKit
import MappedIn

/**
This is a dead-simple example designed to let you make sure you have valid credentials, a venue, and can build with the SDK.
 
 All you need to do is modify the Info.plist file to include your MappedInUsername and MappedInPassword, both of which should have been provided by MappedIn. Then hit run, and after it loads you should see a map displayed on screen.
*/
class ViewController: UIViewController {

    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var venue = [Venue]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Get a list of all venues your credentials can access, and then pass it to a function that loads the full details of the first one.
        MappedIn.getVenues(loadFirstVenue)
    }
    
    // MARK: Functions
    /// Load the full details (Maps, Locations, etc) for the first Venue we find)
    func loadFirstVenue(_ venues: [Venue]) {
        if let venue: Venue = venues.first {
            MappedIn.getVenue(venue, callback: displayVenue)
        } else {
            // Send this back to the main thread to do UI work
            DispatchQueue.main.async {
                let errorMessage = "No venues found. Make sure you set your MappedInUsername and MappedInPassword in your info.plist. If you did, talk to your MappedIn representative to ensure your key has access to a venue"
                self.errorLabel.text = errorMessage
                self.errorLabel.isEnabled = true
                self.errorLabel.isHidden = false
                print(errorMessage);
                self.mapView.isHidden = true
            }
        }
    }
    
    /// Tells the MapView to display a map for a certain venue
    func displayVenue(_ venue: Venue) {
        print("Venue got")
        mapView.venue = venue
        mapView.loadScene()
    }

}

