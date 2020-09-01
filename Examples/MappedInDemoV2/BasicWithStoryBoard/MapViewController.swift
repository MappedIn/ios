//
//  MapViewController.swift
//  mapBox-Test
//
//  Created by Youel Kaisar on 2020-08-27
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mapbox
import Mappedin

class MapViewController: UIViewController{
    
    var venueSlug: String = "mappedin-demo-mall"
    var venue:MiVenue!

    var mapView: MiMapView!

    @IBOutlet weak var levelUp: UIButton!
    @IBOutlet weak var levelDown: UIButton!
    
    @IBAction func didTapLevelUp(_ sender: UIButton) {
        incrementLevel()
    }

    @IBAction func didTapLevelDown(_ sender: UIButton) {
        decrementLevel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let mappedIn = Mappedin()
        let customStyleURL = Bundle.main.url(forResource: "third_party_style", withExtension: "json")!
        mapView = MiMapView(frame: view.bounds, styleURL: customStyleURL)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.miDelegate = self
        
        
        mappedIn.getVenue(venueSlug: venueSlug, completionHandler: {(resultCode, venue) -> Void in
            self.venue = venue
            self.mapView.loadMap(venue: venue!)
        })
    }

    func incrementLevel() {
        if mapView.canIncrementLevel() {
            mapView.incrementLevel()
        }
    }

    func decrementLevel() {
        if mapView.canDecrementLevel() {
            mapView.decrementLevel()
        }
    }
}

extension MapViewController: MiMapViewDelegate {
    func onTapNothing() {
        
    }
    
    func didTapSpace(space: MiSpace) -> Bool {
        return false
    }
    
    func onTapCoordinates(point: CLLocationCoordinate2D) {

    }
    
    func didTapOverlay(overlay: MiOverlay) -> Bool {
        return false
    }
    
    func onLevelChange(level: MiLevel) {
        mapView.focusOnCurrentLevel(padding: 50)
    }
    
    func onManipulateCamera(gesture: MiGestureType) {
        
    }
    
    func onMapLoaded(status: MiMapStatus) {
        self.mapView.focusOnCurrentLevel()
    }
}
