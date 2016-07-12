//
//  MapViewController.swift
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

import UIKit
import MappedIn

public class MapViewController: UIViewController, MapViewDelegate {
    @IBOutlet weak var mappedinMapView: MapView!
    private var selectedLocation1: Location?
    private var selectedLocation2: Location?
    private var directionsPath: MapView.Path?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.mappedinMapView.delegate = self
        if let venue = MappedInWrapper.venue {
            self.mappedinMapView.venue = venue
            self.mappedinMapView.loadScene()
        }
    }
    
    public func selectLocationByName(name: String) {
        if let venue = MappedInWrapper.venue,
        location = venue.locations.filter({location in
            location.name == name
        }).first {
            self.selectLocation(location)
        }
    }
    
    private func selectLocation(location: Location) {
        if self.selectedLocation1 == nil {
            self.selectedLocation1 = location
            self.selectedLocation2 = nil
        } else if self.selectedLocation2 != nil {
            self.selectedLocation1 = location
            self.selectedLocation2 = nil
        } else {
            self.selectedLocation2 = location
        }
        
        self.updateView()
    }
    
    private func updateView() {
        if let subMapView = self.mappedinMapView {
            self.updateHighlightedPolygons()
            self.updateDirections()
        }
    }
    
    private func updateDirections() {
        if let location1 = self.selectedLocation1,
            location2 = self.selectedLocation2 {
            if let directions = location1.directions(to: location2) {
                let path = MapView.Path(coordinates: directions.path, width: 20, height: 20, color: UIColor.blueColor())
                self.directionsPath = path
                self.mappedinMapView.addPath(path)
            } else {
                if let path = self.directionsPath {
                    self.mappedinMapView.removePath(path)
                    self.directionsPath = nil
                }
            }
        } else {
            if let path = self.directionsPath {
                self.mappedinMapView.removePath(path)
                self.directionsPath = nil
            }
        }
    }
    
    private func updateHighlightedPolygons() {
        self.mappedinMapView.clearHighlightedPolygons()
        
        if let location1 = self.selectedLocation1 {
            for polygon in location1.polygons {
                self.mappedinMapView.highlightPolygon(polygon, color: UIColor.blueColor())
            }
        }
        
        if let location2 = self.selectedLocation2 {
            for polygon in location2.polygons {
                self.mappedinMapView.highlightPolygon(polygon, color: UIColor.blueColor())
            }
        }
    }
    
    
    public func polygonTapped(polygon: Polygon) -> Bool {
        if let location = polygon.locations.first {
            self.selectLocation(location)
            return false
        }
        return true
    }
    
    public func nothingTapped() {
        
    }
    
    public func sceneLoaded() {
        self.updateView()
    }
    public func mapMotionStarted(type: MotionType) {}
    public func mapMotionEnded(type: MotionType) {}
}
