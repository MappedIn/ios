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
    var previousStateMapView: MiMapView!
    var venue:MiVenue!
    var location: MiLocation?
    var startLocation: MiLocation?
    var endLocation: MiLocation?
    var directionInstructions: [MiInstruction]?
    var previousPath: MiPath?
    var selectedPolygons = Set<String>()
    var storeDetailsView: UIView!
    var showTextDirections: UIButton!
    var mainViewController: ViewController!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    override func viewDidLoad() {
        previousStateMapView = mapView
        super.viewDidLoad()
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
        self.dismiss(animated: true, completion: nil)
        self.storeDetailsView.isHidden = true
        self.showTextDirections.isHidden = false
        if let instruction = directionInstructions {
            self.mainViewController.onGetTextDirections(instructions: instruction)
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        self.mapView = self.previousStateMapView
        self.dismiss(animated: true, completion: nil)
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
        
        var directions: (MiDirections, MiPath)? = nil
        if let startLocation = startLocation, let endLocation = endLocation {
            directions = mapView.createNavigationPath(from: startLocation, to: endLocation, pathWidth: 10, pathColor: UIColor.blue)
            previousPath = directions?.1
        }
        
        let startSpaces = directions?.0.pathNodes.first?.spaces.filter { space in
            startLocation?.spaces.contains(space) ?? false
        }
        if let startSpace = startSpaces?.first {
            highlightPathSpace(navigationLocation: .start, space: startSpace)
            if let currentLevel = directions?.0.pathNodes.first?.level {
                mapView.setLevel(level: currentLevel)
            }
            mapView.focusOn(focusable: startSpace, heading: 0, over: 1000.0)
        }
        
        let endSpaces = directions?.0.pathNodes.last?.spaces.filter { space in
            endLocation?.spaces.contains(space) ?? false
        }
        highlightPathSpace(navigationLocation: .end, space: endSpaces?.first)
        
        mapView.focusOnCurrentLevel()
            
        directionInstructions = directions?.0.instructions
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
