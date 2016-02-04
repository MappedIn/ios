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
    @IBOutlet weak var detailsView: UIView!
    
    @IBOutlet var instructionsLabel: UILabel!
    
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
    
    /// Display a big error message if you forget to set up your credentials
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
    
    /// Fill in the details view with location information
    func displayLocationInformation(location: Location) {

        // This image should probably be cached and/or preloaded
        if let image = loadImageFromURL(location.picture?[150]) {
            locationImageView.image = image
        }
        locationTitleLabel.text = location.name
        locationDescriptionLabel.text = location.description
        navigateToLocationButton.hidden = false
        detailsView.hidden = false
    }
    
    /// Clear the highlighted polygons, and either hide the details view, or show the venue information instead of the details of a specific location
    func clearLocationInformation() {
        mapView.clearHighlightedPolygons()
        
        // Use this to display the Venue details instead of hiding the details view
        //if let image = loadImageFromURL(mapView.venue?.logo?[150]) {
        //   locationImageView.image = image
        //}
        
        //locationTitleLabel.text = mapView.venue?.name
        //locationDescriptionLabel.text = "Select a location"
        //navigateToLocationButton.hidden = true
        
        detailsView.hidden = true

    }
    
    func clearDirections() {
        directionsView.hidden = true
        directions = nil
        directionsDestinationPolygon = nil
        mapView.clearPaths(true)
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
        
        // Don't do anything if we'e already in navigation mode
        if directions != nil {
            return
        }
        
        // Clear the old highlight
        mapView.clearHighlightedPolygons()
        
        // If the polygon doesn't belong to any locations, bail out
        if polygon.locations.count == 0 {
            return
        }
        
        // Keep track of this polygon for when we do directions, incase a location has multiple polygons
        currentlySelectedPolygon = polygon
        mapView.highlightPolygon(polygon, color: UIColor.blueColor())
        
        // If the user hit the "Go" button, the next polygon tapped will be the origin for the directions
        if directionsDestinationPolygon != nil {
            // Make sure the polygon actually has entrances
            if polygon.entrances.count > 0 {
                
                // Get directions between the array of entrances for each polygon
                directions = polygon.entrances.directionsTo(directionsDestinationPolygon!.entrances, departFrom: polygon.locations.first, arriveAt: directionsDestinationPolygon!.locations.first)
                
                // Make sure we have a valid path. Everything SHOULD be connected, but you never know.
                if let path = directions?.path {
                    
                    //Draw the path and highlight the starting node
                    mapView.drawPath(path)
                    if let startingNode = directions?.directions?.first?.node {
                        mapView.highlightNode(startingNode)
                    } else {
                        // Incase there are no dirction instructions for some reason
                        mapView.highlightNode(path, index: 0)
                    }
                    // Display the first instruction to the user. You'd also show an icon for the action
                    let instruction = directions?.directions?.first?.instruction
                    instructionsLabel.text = instruction
                    
                    // Set up the directions stepper to let the user jump from one intruction to the other
                    directionsStepper.maximumValue = Double(directions!.directions.count)
                    directionsStepper.value = 0
                } else {
                    locationTitleLabel.text = "No path found."
                }
                
            } else {
                locationTitleLabel.text = "Location has no entrances. Select another."
            }
        // If we aren't starting directions, show the information for the location that belongs to the polygon.
        // There is probably just the one, if there are mutiples it should be something venue specific you know how to handle.
        } else {
            displayLocationInformation(polygon.locations[0])
            
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

    // MARK: Actions
    /// Prompt the user to select where they are starting their navigation from
    @IBAction func navigateToLocationButtonTapped(sender: UIButton) {
        directionsView.hidden = false
        if currentlySelectedPolygon?.entrances.count > 0 {
            instructionsLabel.text = "Select origin"
            directionsDestinationPolygon = currentlySelectedPolygon
        } else {
            instructionsLabel.text = "This location has no entrances, select another"
        }
        
        
    }
    
    /// Multiple maps is usually mutiple floors, so this lets us step up and down then
    @IBAction func mapStepperChanged(sender: UIStepper) {
        mapView.changeMap(Int(sender.value))
    }
    
    /// Walk through the directions, highlighting the right node and displaying the right instruction
    @IBAction func directionsStepperChanged(sender: AnyObject) {
        let index = Int(directionsStepper.value)
        mapView.highlightNode(directions!.directions[index].node)
        instructionsLabel.text = directions!.directions[index].instruction
    }
    
}

