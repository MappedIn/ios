//
//  GetDirectionViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import Mapbox

class GetDirectionsViewController: UIViewController {
    var mapView: MiMapView!
    var venueSlug: String?
    var venue:MiVenue!
    var location: MiLocation?
    var startLocation: MiLocation?
    var endLocation: MiLocation?
    var previousPath: MiPath?
    var selectedPolygons = Set<String>()
    var spaceTapped: MiSpace?
    var directionInstructions: [MiInstruction]?
    @IBOutlet weak var venueLevel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var showLocationLabels: UISwitch!
    @IBOutlet weak var viewDirections: UIButton!
    
    override func viewDidLoad() {
        viewDirections.isHidden = true
        super.viewDidLoad()
        
               
        let mappedIn = Mappedin()
        let customStyleURL = Bundle.main.url(forResource: "third_party_style", withExtension: "json")!
        mapView = MiMapView(frame: view.bounds, styleURL: customStyleURL)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.miDelegate = self

        if let venueSlug = self.venueSlug{
            mappedIn.getVenue(venueSlug: venueSlug, completionHandler: {(resultCode, venue) -> Void in
                self.venue = venue
                self.mapView.loadMap(venue: venue!)
                if let location = self.spaceTapped?.locations.first {
                        self.onLocationUpdate(navigationLocation: NavigationLocation.end, location: location)
                    
                }
            })
        }
    }
    
    func updateDetails() {
        if let location = spaceTapped?.locations.first {
            if let space = spaceTapped {
                mapView.focusOn(focusable: space, heading: 0, padding: 10, over: 1000.0)
                onLocationUpdate(navigationLocation: NavigationLocation.end, location: location)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
            if segue.identifier == "chooseDestination" {
                destination.navLocation = .start
            }
        }
        
        if let destination = segue.destination as?  TextDirectionsViewController {
            destination.instructions = self.directionInstructions
        }
        
        if let destination = segue.destination as? LevelSelectorViewController {
            destination.mapView = mapView
            destination.venue = venue
            destination.venueLevel = venueLevel
        }
    }
    
    
    @IBAction func selectStartLocation(_ sender: Any) {
        performSegue(withIdentifier: "chooseDestination", sender: nil)
    }
    
    @IBAction func didToggleLocationLabels(_ sender: Any) {
        if ( showLocationLabels.isOn ) {
            mapView.displayLocationLabels()
        } else {
            mapView.hideLocationLabels()
        }
        
    }
    
    @IBAction func viewTextDirections(_ sender: Any) {
        performSegue(withIdentifier: "viewTextDirections", sender: nil)
    }
    
    @IBAction func didTapLevelSelector(_ sender: Any) {
        performSegue(withIdentifier: "levelSelectorSegue2", sender: nil)
    }
}

extension GetDirectionsViewController: MiMapViewDelegate {
    func onMapLoaded(status: MiMapStatus) {
        self.mapView.focusOnCurrentLevel()
    }
    
    func onManipulateCamera(gesture: MiGestureType) {
    }

    func onTapNothing() {
    }

    func didTapSpace(space: MiSpace) -> Bool {
        startLocation = space.locations.first
        onLocationUpdate(navigationLocation: NavigationLocation.end, location: location)
        return true
    }

    func onTapCoordinates(point: CLLocationCoordinate2D) {
    }

    func didTapOverlay(overlay: MiOverlay) -> Bool {
        return true
    }

    func createLabelView(text: String, padding: Double = 5) -> UIView {
        return UIView()
    }
    
    func onLevelChange(level: MiLevel) {
        mapView.focusOnCurrentLevel(padding: 50)
    }
}

extension GetDirectionsViewController: NavigationDelegate {
    func onLocationUpdate(navigationLocation: NavigationLocation, location: MiLocation?) {

        if (startLocation != nil && endLocation != nil) {
            if let path = previousPath {
                mapView.removePath(path: path)
                previousPath = nil
            }
            mapView.clearAllPolygonStyles()
        }

        switch navigationLocation {
        case .start:
            if let startSpace = location?.spaces.first {
                if let prevLocation = startLocation {
                    for space in prevLocation.spaces {
                        mapView.clearPolygonStyle(id: space.id)
                    }
                }

                
                for space in startLocation?.spaces ?? [] {
                    highlightPathSpace(navigationLocation: .start, space: space)
                }
                
                mapView.focusOn(focusable: startSpace, heading: 0, over: 1000.0)
            }

        startLocation = location
        case .end:
            if let prevLocation = endLocation {
                for space in prevLocation.spaces {
                    mapView.clearPolygonStyle(id: space.id)
                }
            }

            if (location?.spaces.first) != nil {
                endLocation = location
                for space in endLocation?.spaces ?? [] {
                    highlightPathSpace(navigationLocation: .end, space: space)
                }
            }
        }

        startButton.setAttributedTitle(NSAttributedString(string: startLocation?.name ?? "Enter your starting location", attributes: [NSAttributedString.Key.foregroundColor: startLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)

        endButton.setAttributedTitle(NSAttributedString(string: endLocation?.name ?? "Enter your destination", attributes: [NSAttributedString.Key.foregroundColor: endLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)

        var directions: (MiDirections, MiPath)? = nil
        if let startLocation = startLocation, let endLocation = endLocation {
            directions = mapView.createNavigationPath(from: startLocation, to: endLocation, pathWidth: 10, pathColor: UIColor.blue)
            previousPath = directions?.1
            self.viewDirections.isHidden = false
            
        }
        
        
        let startSpaces = directions?.0.pathNodes.first?.spaces.filter { space in
            startLocation?.spaces.contains(space) ?? false
        }
        if let startSpace = startSpaces?.first {
            highlightPathSpace(navigationLocation: .start, space: startSpace)
            if let currentLevel = directions?.0.pathNodes.first?.level {
                mapView.setLevel(level: currentLevel)
            }
        }

        let endSpaces = directions?.0.pathNodes.last?.spaces.filter { space in
            endLocation?.spaces.contains(space) ?? false
        }
        highlightPathSpace(navigationLocation: .end, space: endSpaces?.first)
        
        mapView.focusOnCurrentLevel(padding: 0, over: 1000.0)
        
        self.directionInstructions = directions?.0.instructions
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
