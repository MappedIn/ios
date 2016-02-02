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
class ViewController: UIViewController, MapViewDelegate {
    
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
    func loadFirstVenue(venues: [Venue]) {
        if let venue: Venue = venues.first {
            MappedIn.getVenue(venue, callback: displayVenue)
        } else {
            // Send this back to the main thread to do UI work
            dispatch_async(dispatch_get_main_queue()) {
                let errorMessage = "No venues found. Make sure you set your MappedInUsername and MappedInPassword in your info.plist. If you did, talk to your MappedIn representative to ensure your key has access to a venue"
                self.errorLabel.text = errorMessage
                self.errorLabel.enabled = true
                self.errorLabel.hidden = false
                print(errorMessage);
                self.mapView.hidden = true
            }
        }
    }
    
    /// Tells the MapView to display a map for a certain venue
    func displayVenue(venue: Venue) {
        print("Venue got")
        mapView.venue = venue
        mapView.loadScene()
    }
    
    // MARK: MapViewDelegate
    /// Since data is being pulled down from the Internet, this is called when the scene is finished loading and ready for use.
    func sceneLoaded() {
        print("Scene loaded!")
    }
    
    /// Called when a user taps on a polygon in the MapView and it belongs to one or more locations
    /// Parameter location: The Location(s) associated with the polygon. Often one, but could depend on the map
    func locationSelected(location: [Location]){
        
    }
    
    /// Called when a user taps a specific polygon
    /// Parameter polygon: the Polygon the user tapped on
    func polygonSelected(polygon: Polygon) {
        
    }
    
    /// Called when the user cleared their location selction. Useful to let you clear any aditional information you were displaying for the location
    func locationsCleared() {
        
    }
    
    /// Called when the user has started moving the map around
    /// Parameter type: The type of motion being performed (Zooming, Panning, Rotating, Multi)
    func mapMotionStarted(type:MotionType) {
        
    }
    
    /// Called when the user has stopped moving the map
    /// Parameter type: The type of motion that was being pergormed (Zooming, Panning, Rotating, Multi)
    func mapMotionEnded(type:MotionType) {
        
    }

    
}

