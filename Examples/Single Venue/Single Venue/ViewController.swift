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
    
    fileprivate var directionsDestinationPolygon: Polygon?
    fileprivate var currentlySelectedPolygon: Polygon?
    fileprivate var directions: Directions?
    
    fileprivate var directionsHighlightColor:UIColor = UIColor(red: 1.0, green: 0.514, blue: 0.016, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Get a list of all venues your credentials can access, and then pass it to a function that loads the full details of the first one.
        MappedIn.getVenues(loadFirstVenue)
    }
    
    // MARK: Functions
    /// Load the full details (Maps, Locations, etc) for the first Venue we find)
    func loadFirstVenue(_ venues: [Venue]) {
        if let venue: Venue = venues.first {
            MappedIn.getVenue(venue,
                locationGenerator: { data in
                    // You could have several different kinds of locations, and figure out what kind to create using the "type" parameter, or the kind of data it contains
                    return CustomLocation(data)
                }, callback: displayVenue)
        } else {
            logError("No venues found. Make sure you set your MappedInUsername and MappedInPassword in your info.plist. If you did, talk to your MappedIn representative to ensure your key has access to a venue")
        }
    }
    
    /// Tells the MapView to display a map for a certain venue
    func displayVenue(_ venue: Venue) {
        print("Venue loaded, displaying")
        mapView.venue = venue
        mapView.loadScene()
        clearLocationInformation()
    }
    
    /// Display a big error message if you forget to set up your credentials
    func logError(_ errorMessage: String) {
        // Send this back to the main thread to do UI work
        DispatchQueue.main.async {
            
            self.errorLabel.text = errorMessage
            self.errorLabel.isEnabled = true
            self.errorLabel.isHidden = false
            print(errorMessage);
            self.mapView.isHidden = true
        }
    }
    
    /// Fill in the details view with location information
    func displayLocationInformation(_ location: Location) {
        let customLocation = location as! CustomLocation
        // This image should probably be cached and/or preloaded
        if let logo = loadImageFromURL(customLocation.logo?[150]) {
            locationImageView.image = logo
        }
        locationTitleLabel.text = location.name
        locationDescriptionLabel.text = customLocation.description
        navigateToLocationButton.isHidden = false
        detailsView.isHidden = false
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
        
        detailsView.isHidden = true

    }
    
    func clearDirections() {
        directionsView.isHidden = true
        directions = nil
        directionsDestinationPolygon = nil
        mapView.removeAllPaths()
    }
    
    func loadImageFromURL(_ url: URL?) -> UIImage? {
        if url == nil {
            return UIImage()
        }
        if let imageData = try? Data(contentsOf: url!) {
            return UIImage(data: imageData)
        }
        return UIImage()
    }
    
    // MARK: MapViewDelegate
    /// Since data is being pulled down from the Internet, this is called when the scene is finished loading and ready for use.
    func sceneLoaded() {
        print("Scene loaded!")
        let mapCount = mapView.venue?.maps.count
        if mapCount! > 0 {
            mapStepper.maximumValue = Double(mapCount!)
        } else {
            logError("Something horrible has happened, because your venue has no maps. Check your internet connection, or contacted your MappedIn representative")
        }
        
    }
    
    /// Called when a user taps a specific polygon
    /// Parameter polygon: the Polygon the user tapped on
    func polygonTapped(_ polygon: Polygon) -> Bool {
        
        // Don't do anything if we'e already in navigation mode
        if directions != nil {
            return false
        }
        
        // Clear the old highlight
        mapView.clearHighlightedPolygons()
        
        // If the polygon doesn't belong to any locations, bail out
        if polygon.locations.count == 0 {
            return false
        }
        
        // Keep track of this polygon for when we do directions, incase a location has multiple polygons
        currentlySelectedPolygon = polygon
        mapView.highlightPolygon(polygon)
        //mapView.camera.focusOn(polygon)
        
        // If the user hit the "Go" button, the next polygon tapped will be the origin for the directions
        if let destPoly = directionsDestinationPolygon {
            // Make sure the polygon actually has entrances
            if polygon.entrances.count > 0 {
                
                // Get directions between the array of entrances for each polygon
                directions = polygon.entrances.directionsTo(destPoly.entrances)
                
                // Make sure we have a valid path. Everything SHOULD be connected, but you never know.
                if let path = directions?.path {
                    
                    let mapPath = MapView.Path(coordinates: path)
                    //Draw the path and highlight the end point
                    mapView.addPath(mapPath)
                    
                    mapView.camera.focusOn([polygon, destPoly])
                    mapView.highlightPolygon(directionsDestinationPolygon!, color: directionsHighlightColor)
                    
                    // Display the first instruction to the user. You'd also show an icon for the action
                    let instruction = directions?.instructions.first?.description
                    instructionsLabel.text = instruction
                    
                    // Set up the directions stepper to let the user jump from one intruction to the other
                    directionsStepper.maximumValue = Double(directions!.instructions.count)
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
            Analytics.selectedLocation(polygon.locations[0])
            displayLocationInformation(polygon.locations[0])
            
        }
        return false
        
    }
    
    /// Called when the user cleared their location selction. Useful to let you clear any aditional information you were displaying for the location
    func nothingTapped() {
        clearLocationInformation()
        clearDirections()
        mapView.removeAllMakers()
    }
    
    /// Called when the user has started moving the map around
    /// Parameter type: The type of motion being performed (Zooming, Panning, Rotating, Multi)
    func mapMotionStarted(_ type:MotionType) {
        
    }
    
    /// Called when the user has stopped moving the map
    /// Parameter type: The type of motion that was being pergormed (Zooming, Panning, Rotating, Multi)
    func mapMotionEnded(_ type:MotionType) {
        
    }

    // MARK: Actions
    /// Prompt the user to select where they are starting their navigation from
    @IBAction func navigateToLocationButtonTapped(_ sender: UIButton) {
        directionsView.isHidden = false
        if (currentlySelectedPolygon?.entrances.count)! > 0 {
            instructionsLabel.text = "Select origin"
            directionsDestinationPolygon = currentlySelectedPolygon
        } else {
            instructionsLabel.text = "This location has no entrances, select another"
        }
        
        
    }
    
    /// Multiple maps is usually mutiple floors, so this lets us step up and down then
    @IBAction func mapStepperChanged(_ sender: UIStepper) {
        mapView.changeMap(Int(sender.value))
    }
    
    /// Walk through the directions, displaying the right instruction
    @IBAction func directionsStepperChanged(_ sender: AnyObject) {
        let index = Int(directionsStepper.value)
        mapView.camera.focusOn(directions!.instructions[index].node)
        instructionsLabel.text = directions!.instructions[index].description
    }
    
    @IBAction func showLocationsButtonPressed(_ sender: UIButton) {
        mapView.removeAllMakers()
        
        for polygon in mapView.venue!.polygons {
            if let location = polygon.locations.first {
                let marker = MapViewMarker2DLabel(text: location.name)
                marker.anchor = mapView.getAnchor(polygon)
                mapView.addMarker(marker)
            }
        }
    }
    
}

