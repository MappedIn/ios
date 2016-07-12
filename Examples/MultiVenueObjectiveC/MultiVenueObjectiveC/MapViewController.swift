//
//  MapViewController.swift
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

import UIKit
import MappedIn

class MapViewController: UIViewController, MapViewDelegate {
    @IBOutlet weak var mappedinMapView: MapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mappedinMapView.delegate = self
        if let venue = MappedInWrapper.venue {
            self.mappedinMapView.venue = venue
            self.mappedinMapView.loadScene()
        }
    }
    
    func sceneLoaded() {
        
    }
    
    func polygonTapped(polygon: Polygon) -> Bool {
        return false
    }
    
    func nothingTapped() {
        
    }
    
    func mapMotionStarted(type: MotionType) {}
    func mapMotionEnded(type: MotionType) {}
}
