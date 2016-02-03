//
//  ViewController.swift
//  Hello World
//
//  Created by Paul Bernhardt on 2016-01-29.
//  Copyright © 2016 MappedIn. All rights reserved.
//

import UIKit
import MappedIn
import Foundation

/**
 This is a dead-simple example designed to let you make sure you have valid credentials, a venue, and can build with the SDK.
 
 All you need to do is modify the Info.plist file to include your MappedInUsername and MappedInPassword, both of which should have been provided by MappedIn. Then hit run, and after it loads you should see a map displayed on screen.
 */
class ViewController: UIViewController, MapViewDelegate {
    
    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var mapStepper: UIStepper!
    
    //MARK: Directions controls
    @IBOutlet weak var directionsView: UIView!
    @IBOutlet weak var directionsStepper: UIStepper!
    
    //MARK: Details controls
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet var locationTitleLabel: UILabel!
    @IBOutlet var locationDescriptionLabel: UILabel!
    @IBOutlet var navigateToLocationButton: UIButton!
    
    @IBOutlet var instructionsLabel: UILabel!
    
    @IBAction func navigateToLocationButtonTapped(sender: UIButton) {
        directionsView.hidden = false
        if currentlySelectedPolygon?.entrances.count > 0 {
            instructionsLabel.text = "Select origin"
            directionsDestinationPolygon = currentlySelectedPolygon
        } else {
            instructionsLabel.text = "This location has no entrances, select another"
        }
        
        
    }
    
    @IBOutlet weak var detailsView: UIView!
    
    @IBAction func mapStepperChanged(sender: UIStepper) {
        mapView.changeMap(Int(sender.value))
    }
    
    @IBAction func directionsStepperChanged(sender: AnyObject) {
        let index = Int(directionsStepper.value)
        mapView.highlightNode(directions!.path, index: index)
        instructionsLabel.text = directions!.directions[index].instruction
    }
    
    private var directionsDestinationPolygon: Polygon?
    private var currentlySelectedPolygon: Polygon?
    private var directions: Directions?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Get a list of all venues your credentials can access, and then pass it to a function that loads the full details of the first one.
        MappedIn.getVenues(loadFirstVenue)
    }
    
    // MARK: Functions
    /// Load the full details (Maps, Locations, etc) for the first Venue we find)
    func loadFirstVenue(venues: [Venue]) {
        if let venue: Venue = venues.first {
            MappedIn.getVenue(venue, callback: displayVenue)
        } else {
            logError("No venues found. Make sure you set your MappedInUsername and MappedInPassword in your info.plist. If you did, talk to your MappedIn representative to ensure your key has access to a venue")
        }
    }
    
    /// Tells the MapView to display a map for a certain venue
    func displayVenue(venue: Venue) {
        print("Venue loaded, displaying")
        mapView.venue = venue
        mapView.loadScene()
        clearLocationInformation()
    }
    
    func logError(errorMessage: String) {
        // Send this back to the main thread to do UI work
        dispatch_async(dispatch_get_main_queue()) {
            
            self.errorLabel.text = errorMessage
            self.errorLabel.enabled = true
            self.errorLabel.hidden = false
            print(errorMessage);
            self.mapView.hidden = true
        }
    }
    
    func displayLocationInformation(location: Location) {

        if let image = loadImageFromURL(location.picture?[150]) {
            locationImageView.image = image
        }
        locationTitleLabel.text = location.name
        locationDescriptionLabel.text = location.description
        navigateToLocationButton.hidden = false
        if directions == nil {
            instructionsLabel.text = ""
        }
    }
    
    func clearLocationInformation() {
        if let image = loadImageFromURL(mapView.venue?.logo?[150]) {
           locationImageView.image = image
        }
        
        locationTitleLabel.text = mapView.venue?.name
        locationDescriptionLabel.text = "Select a location"
        navigateToLocationButton.hidden = true
    }
    
    func clearDirections() {
        directionsView.hidden = true
        directions = nil
        directionsDestinationPolygon = nil
    }
    
    func loadImageFromURL(url: NSURL?) -> UIImage? {
        if url == nil {
            return UIImage()
        }
        if let imageData = NSData(contentsOfURL: url!) {
            return UIImage(data: imageData)
        }
        return UIImage()
    }
    
    // MARK: MapViewDelegate
    /// Since data is being pulled down from the Internet, this is called when the scene is finished loading and ready for use.
    func sceneLoaded() {
        print("Scene loaded!")
        let mapCount = mapView.venue?.maps?.count
        if mapCount > 0 {
            mapStepper.maximumValue = Double(mapCount!)
        } else {
            logError("Something horrible has happened, because your venue has no maps. Check your internet connection, or contacted your MappedIn representative")
        }
        
    }
    
    /// Called when a user taps a specific polygon
    /// Parameter polygon: the Polygon the user tapped on
    func polygonTapped(polygon: Polygon) {
        
        
        mapView.clearHighlightedPolygons()
        if polygon.locations.count > 0 {
            currentlySelectedPolygon = polygon
            mapView.highlightPolygon(polygon)
        
            if directionsDestinationPolygon != nil {
                if polygon.entrances.count > 0 {
                
                    directions = polygon.entrances.directionsTo(directionsDestinationPolygon!.entrances)
                    if let path = directions?.path {
                        mapView.drawPath(path)
                        mapView.highlightNode(path, index: 0)
                        instructionsLabel.text = directions!.directions[0].instruction
                        directionsStepper.maximumValue = Double(path.count)
                        directionsStepper.value = 0
                    } else {
                        locationTitleLabel.text = "No path found."
                    }
                    
                } else {
                    locationTitleLabel.text = "Location has no entrances. Select another."
                }
            
            } else {
            
                displayLocationInformation(polygon.locations[0])
            
            }
        }
    }
    
    /// Called when the user cleared their location selction. Useful to let you clear any aditional information you were displaying for the location
    func nothingTapped() {
        clearLocationInformation()
        clearDirections()
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

