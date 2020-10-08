//
//  ViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import Mapbox

class ViewController: UIViewController {

    var mapView: MiMapView!
    
    var venueSlug: String = "mappedin-demo-mall"
    var venue: MiVenue!
    var connectionOverlaysMap: [String: MiInstruction] = [:]
    var startLocation: MiLocation?
    var selectedPolygons = Set<String>()
    var directions: MiDirections?
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var storeDetailsView: StoreDetailsView!
    @IBOutlet weak var venueLevel: UILabel!
    @IBOutlet weak var cancelSearchLocation: UIButton!
    var viewDirections: UIButton!
    @IBOutlet weak var tabBar: UITabBarItem!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Set properties for segue to LocationViewController
        if let destination = segue.destination as? LocationViewController {
            destination.categories = (venue?.categories ?? []).map { category in
                category.locations = (category as MiCategory).locations.sorted(by: { (location1, location2) in
                    location1.name < location2.name
                })
                return category
            }
            
            let otherLocations = venue?.locations.filter {
                $0.categories.isEmpty && !$0.spaces.isEmpty
            } ?? []
            let name = destination.categories.isEmpty ? "" : "Other"
            let otherCategory = MiCategory(id: "", name: name)
            otherCategory.locations = otherLocations
            destination.categories.append(otherCategory)
            destination.navDelegate = self
            if segue.identifier == "StartSegue" {
                destination.navLocation = .start
            } 
        }
        
        // Set properties for segue to LocationDetailsViewController
        if let destination = segue.destination as? LocationDetailsViewController{
            destination.location = startLocation
        }
        
        // Set properties for segue to GetDirectionsViewController
        if let destination = segue.destination as? GetDirectionsViewController {
            destination.location = startLocation
            destination.endLocation = startLocation
            destination.venue = self.venue
            destination.mapView = mapView
            destination.storeDetailsView = self.storeDetailsView
            destination.showTextDirections = self.viewDirections
            destination.mainViewController = self
        }
        
        // Set properties for segue to LevelSelectorViewContoller
        if let destination = segue.destination as? LevelSelectorViewController {
            destination.mapView = mapView
            destination.venue = venue
            destination.venueLevel = venueLevel
        }
        
        // Set properties for segue to TextDirectionsViewCOntroller
        if let destination = segue.destination as? TextDirectionsViewController {
            destination.directions = directions        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mappedin = Mappedin(mappedinKey: "5f4e59bb91b055001a68e9d9", mappedinSecret: "gmwQbwuNv7cvDYggcYl4cMa5c7n0vh4vqNQEkoyLRuJ4vU42")
        
        
        mapView = MiMapView(frame: view.bounds, styleURL: nil)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        
        mapView.miDelegate = self
        storeDetailsView.delegate = self
        
        if let navigationBar = self.navigationController?.navigationBar {
            let image = UIImage(named: "MappedinLogo")
            let imageView = UIImageView(frame: CGRect(x: navigationBar.frame.width/2 - 40, y:0, width: 15, height: 25))
            imageView.image = image
            navigationBar.addSubview(imageView)
            let label = UILabel(frame: CGRect(x: navigationBar.frame.width/2 - 30 + imageView.frame.width, y: 3, width: 200, height: 25))
            label.text = "mobile"
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 22, weight: .thin)
            navigationBar.addSubview(label)
            
        }
        
        // Create view text directions button
        createViewTextDirectionsButtion()
        
        mappedin.getVenue(venueSlug: self.venueSlug) { (result, venue) in
            if let venue = venue {
                self.mapView.loadMap(venue: venue)
                self.venue = venue
                self.venueName.text = venue.name + ":"
                self.venueLevel.text = self.mapView.currentLevel?.name
            }
        }
    }
    
    func handleNavigationTapping(space: MiSpace) {
        if let location = space.locations.first {
            mapView.focusOn(focusable: space, heading: 0, padding: 10, over: 1000.0)
            onLocationUpdate(navigationLocation: NavigationLocation.start, location: location)
        }
    }
    
    func onGetTextDirections(directions: MiDirections) {
        self.directions = directions
    }
    
    @IBAction func chooseLocation(_ sender: Any) {
        performSegue(withIdentifier: "startSegue", sender: nil)
    }
    
// TODO : Place this view in a separate xib file
    @IBAction func didTapPickerView(_ sender: Any) {
        performSegue(withIdentifier: "LocationSelectorSegue", sender: nil)
    }
    
    @IBAction func didTapCancelLocation(_ sender: Any) {
        resetMap()
    }
    
    func resetMap() {
        mapView.clearAllPolygonStyles()
        mapView.removeAllPaths()
        mapView.removeAllOverlays()
        mapView.focusOnCurrentLevel(padding: 10, over: 1000.0)
        storeDetailsView.isHidden = true
        cancelSearchLocation.isHidden = true
        viewDirections.isHidden = true
        startButton.setAttributedTitle(NSAttributedString(string: "Choose a location", attributes: [NSAttributedString.Key.foregroundColor: startLocation != nil ? UIColor.lightGray : UIColor.lightGray]), for: .normal)
    }
    
    func createViewTextDirectionsButtion() {
        viewDirections = UIButton()
        viewDirections.translatesAutoresizingMaskIntoConstraints = false
        viewDirections.setTitle("View Text Directions", for: .normal)
        viewDirections.setTitleColor( .white, for: .normal)
        viewDirections.addTarget(self, action: #selector(didTapViewDirections), for: .touchUpInside)
        viewDirections.backgroundColor = .darkGray
        viewDirections.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        view.addSubview(viewDirections)
        viewDirections.heightAnchor.constraint(equalToConstant: 50).isActive = true
        viewDirections.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        viewDirections.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        viewDirections.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        viewDirections.isHidden = true
    }
    
}

extension ViewController: StoreDetailsDelegate {
    func didTapViewDetails() {
        performSegue(withIdentifier: "LocationDetailsSegue", sender: nil)
    }
    
    func didTapGetDirections() {
        performSegue(withIdentifier: "GetDirectionsSegue", sender: nil)
    }
    
    @objc func didTapViewDirections() {
        performSegue(withIdentifier: "viewTextDirections", sender: nil)
    }
}

extension ViewController: MiMapViewDelegate {
    func onTapNothing() {
        // Called when a tap doesn't hit any spaces
    }
    
    func didTapSpace(space: MiSpace) -> Bool {
        self.handleNavigationTapping(space: space)
        if let location = space.locations.first {
            storeDetailsView.location = location
            storeDetailsView.isHidden = false
            startLocation = location
        }
        return true
    }
    
    func onTapCoordinates(point: CLLocationCoordinate2D) {
        // Called when the map is tapped and provides the coordinates of the tap
    }
    
    func didTapOverlay(overlay: MiOverlay) -> Bool {
        // Called when an overlay is tapped and provides which overlay was tapped
        // Return true to stop the tap
        // Return false to allow the tap to fall through and trigger other events
        if let instruction = connectionOverlaysMap[overlay.id] {
            if let action = instruction.action as? TakeConnection {
                mapView.setLevel(level: action.toLevel)
            } else if let action = instruction.action as? ExitConnection {
                mapView.setLevel(level: action.fromLevel)
            }
        }
        return true
    }
    
    func onLevelChange(level: MiLevel) {
        // Called when the level is changed and provides the new level
        venueLevel.text = level.name
    }
    
    func onManipulateCamera(gesture: MiGestureType) {
        // Called when the user manipulates the camera
    }
    
    func onMapLoaded(status: MiMapStatus) {
        // Called when the `MiMapView` has finished loading both the view and the venue data
    }
}

extension ViewController: NavigationDelegate {
    func onLocationUpdate(navigationLocation: NavigationLocation, location: MiLocation?) {
    
        resetMap()
        
        if let startSpace = location?.spaces.first {
            if let prevLocation = startLocation {
                for space in prevLocation.spaces {
                    mapView.clearPolygonStyle(id: space.id)
                }
            }
            
            startLocation = location
            storeDetailsView.location = location
            viewDirections.isHidden = true
            storeDetailsView.isHidden = false
            cancelSearchLocation.isHidden = false
            venueLevel.text = startSpace.level?.name
            
            startButton.setAttributedTitle(NSAttributedString(string: startLocation?.name ?? "Choose a location", attributes: [NSAttributedString.Key.foregroundColor: startLocation != nil ? UIColor.lightGray : UIColor.lightGray]), for: .normal)
            
            for space in startLocation?.spaces ?? [] {
                
                highlightPathSpace(navigationLocation: .start, space: space)
            }
            if let startLevel = startSpace.navigatableNodes.first?.level {
                if (mapView.currentLevel?.id != startLevel.id) {
                    mapView.setLevel(level: startLevel)
                }
            }
            
            mapView.focusOn(focusable: startSpace, heading: 0, over: 1000.0)
        
        }
    }
    
    func highlightPathSpace(navigationLocation: NavigationLocation, space: MiSpace?) {
        if let space = space {
            let highlight: MiColorProperties
            let outline: MiOutlineProperties
            switch navigationLocation {
            case .start:
                highlight = MiColorProperties(color: UIColor.init(red: 0.0, green: 1.0, blue: 50.0/255.0, alpha: 1.0), opacity: 1.0)
                outline = MiOutlineProperties(color: UIColor.init(red: 0.0, green: 140.0/255.0, blue: 20.0/255.0, alpha: 1.0), width: 5.0, opacity: 1.0)
                break
            case .end:
                highlight = MiColorProperties(color: UIColor.init(red: 1.0, green: 218.0/255.0, blue: 185.0/255.0, alpha: 1.0), opacity: 1.0)
                outline = MiOutlineProperties(color: UIColor.init(red: 220.0/255.0, green: 20.0/255.0, blue: 60.0/255.0, alpha: 1.0), width: 5.0, opacity: 1.0)
            }
            selectSpace(space: space, highlightProperty: highlight, outlineProperty: outline)
        }
    }
    
    func selectSpace(space: MiSpace, highlightProperty: MiColorProperties, outlineProperty: MiOutlineProperties) {
        mapView.setPolygonColor(id: space.id, styleProperties: highlightProperty)
        mapView.setPolygonOutline(id: space.id, styleProperties: outlineProperty)
        selectedPolygons.insert(space.id)
    }
}

