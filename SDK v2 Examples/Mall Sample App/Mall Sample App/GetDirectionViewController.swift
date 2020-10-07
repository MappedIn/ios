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
    var venue:MiVenue!
    var location: MiLocation?
    var startLocation: MiLocation?
    var endLocation: MiLocation?
    var directionsToDestination: MiDirections?
    var previousPath: MiPath?
    var selectedPolygons = Set<String>()
    var storeDetailsView: UIView!
    var showTextDirections: UIButton!
    var mainViewController: ViewController!
    @IBOutlet weak var accessibilityToggle: UISwitch!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var showDirectionsButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        showDirectionsButton.isEnabled = false
        endButton.setAttributedTitle(NSAttributedString(string: endLocation?.name ?? "Enter your destination", attributes: [NSAttributedString.Key.foregroundColor: endLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)
        
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
            if segue.identifier == "startLocation" {
                destination.navLocation = .start
            } else if segue.identifier == "endLocation" {
                destination.navLocation = .end
            }
        }
    }
    
    
    @IBAction func didTapShowDirections(_ sender: Any) {
        var navigationPath: MiNavigationPath? = nil
        if let startLocation = startLocation, let endLocation = endLocation {
            if (!accessibilityToggle.isOn) {
                navigationPath = mapView.createNavigationPath(from: startLocation, to: endLocation, accessible: false, pathWidth: 10, pathColor: UIColor.blue)
            } else {
                navigationPath = mapView.createNavigationPath(from: startLocation, to: endLocation, accessible: true, pathWidth: 10, pathColor: UIColor.blue)
            }
            
            previousPath = navigationPath?.path
        }
        
        let startSpaces = navigationPath?.directions.pathNodes.first?.spaces.filter { space in
            startLocation?.spaces.contains(space) ?? false
        }
        if let startSpace = startSpaces?.first {
            highlightPathSpace(navigationLocation: .start, space: startSpace)
            if let currentLevel = navigationPath?.directions.pathNodes.first?.level {
                mapView.setLevel(level: currentLevel)
            }
            mapView.focusOn(focusable: startSpace, heading: 0, over: 1000.0)
        }
        
        let endSpaces = navigationPath?.directions.pathNodes.last?.spaces.filter { space in
            endLocation?.spaces.contains(space) ?? false
        }
        highlightPathSpace(navigationLocation: .end, space: endSpaces?.first)
        
        var overlay: MiOverlay?
        if let endLocationEntrance = endSpaces?.first?.entrances.first {
            let image = UIImage(named: "destinationIcon")
            let coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:  CLLocationDegrees(endLocationEntrance.lat), longitude: CLLocationDegrees(endLocationEntrance.lon))
            overlay = MiOverlay(coordinates: coordinates, level: (endLocation?.spaces.first?.level)!, image: image!)
        }
        mainViewController.venueLevel.text = mapView.currentLevel?.name
        mapView.focusOnCurrentLevel()
        
        var overlays = addConnectionOverlays(navigationPath: navigationPath)
        if let overlay = overlay {
            overlays.append(overlay)
        }
        mapView.displayOverlays(overlays: overlays)
        
        directionsToDestination = navigationPath?.directions
        self.dismiss(animated: true, completion: nil)
        self.storeDetailsView.isHidden = true
        self.showTextDirections.isHidden = false
        if let directions = directionsToDestination {
            self.mainViewController.onGetTextDirections(directions: directions)
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func addConnectionOverlays (navigationPath: MiNavigationPath?) -> [MiOverlay] {
        
        var connectionOverlays: [MiOverlay] = []
        var connectionOverlaysMap: [String: MiInstruction] = [:]
        
        if let navPath = navigationPath {
            for instruction in navPath.directions.instructions {
                var image: UIImage? = nil
                if let action = instruction.action as? TakeConnection {
                    if action.fromLevel.elevation < action.toLevel.elevation {
                        switch action.connection.type {
                            case .stairs:
                                image = UIImage(named: "StairsUp")
                            case .escalator:
                                image = UIImage(named: "EscalatorUp")
                            case .elevator:
                                image = UIImage(named: "ElevatorUp")
                            case .ramp:
                                image = UIImage(named: "RampUp")
                            default:
                                image = nil
                        }
                    } else {
                        switch action.connection.type {
                            case .stairs:
                                image = UIImage(named: "StairsDown")
                            case .escalator:
                                image = UIImage(named: "EscalatorDown")
                            case .elevator:
                                image = UIImage(named: "ElevatorDown")
                            case .ramp:
                                image = UIImage(named: "RampDown")
                            default:
                                image = nil
                        }
                    }
    
                    if let image = image {
                        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 55, height: 55))
                        backgroundView.backgroundColor = .black
                        backgroundView.layer.cornerRadius = 5
                        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                        imageView.image = image
                        imageView.center = backgroundView.convert(backgroundView.center, from:backgroundView.superview)
                        backgroundView.addSubview(imageView)
                        let overlay = MiOverlay(latitude: instruction.node.lat, longitude: instruction.node.lon, level: action.fromLevel, view: backgroundView)
                        connectionOverlays.append(overlay)
                        connectionOverlaysMap[overlay.id] = instruction
                    }
                }
            }
        }
        mainViewController.connectionOverlaysMap = connectionOverlaysMap
        return connectionOverlays
    }

}

extension GetDirectionsViewController: NavigationDelegate {
    func onLocationUpdate(navigationLocation: NavigationLocation, location: MiLocation?) {
 
        if let path = previousPath {
            mapView.removePath(path: path)
            previousPath = nil
        }
        mapView.clearAllPolygonStyles()

        
        switch navigationLocation {
        case .start:
            if let startSpace = location?.spaces.first {
                if let prevLocation = startLocation {
                    for space in prevLocation.spaces {
                        mapView.clearPolygonStyle(id: space.id)
                    }
                }
                
                startLocation = location
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
        
        startButton.setAttributedTitle(NSAttributedString(string: startLocation?.name ?? "Choose a location", attributes: [NSAttributedString.Key.foregroundColor: startLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)
        
        showDirectionsButton.isEnabled = true
        
    
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
