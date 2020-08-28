//
//  MapViewController.swift
//  mapBox-Test
//
//  Created by Youel Kaisar on 2020-08-27
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mapbox
import MappedIn

class MapViewController: UIViewController{
    
    var venueSlug: String?
    var venue:MiVenue!

    var mapView: MiMapView!
    
    var startLocation: MiLocation?
    var endLocation: MiLocation?
    var selectedPolygons = Set<String>()
    var previousPath: MiPath?

    @IBOutlet weak var levelUp: UIButton!
    @IBOutlet weak var levelDown: UIButton!
    @IBOutlet weak var toggle3D: UISwitch!
    @IBOutlet weak var addOverlaysOn: UISwitch!
    @IBOutlet weak var recenter: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
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
            if segue.identifier == "StartSegue" {
                destination.navLocation = .start
            } else if segue.identifier == "EndSegue" {
                destination.navLocation = .end
            }
        }
    }
    
    @IBAction func didTapLevelUp(_ sender: UIButton) {
        incrementLevel()
    }

    @IBAction func didTapLevelDown(_ sender: UIButton) {
        decrementLevel()
    }

    //displays 3D layers and hides 2D when switch is on, and hides 3D layers and displays 2D when off
    @IBAction func didToggle3D(_ sender: UISwitch) {
        toggle3D(enable: toggle3D.isOn)
    }
    
    @IBAction func recenter(_ sender: Any) {
        recenter.isHidden = true
        //TODO: support geofence in SDK to make it convienent to detect if user is too far from venue
        mapView.userTrackingMode = MGLUserTrackingMode.follow
    }

    func toggle3D(enable: Bool) {
        if enable {
            show3DLayers()
        } else {
            hide3DLayers()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let mappedIn = MappedIn()
        let customStyleURL = Bundle.main.url(forResource: "third_party_style", withExtension: "json")!
        mapView = MiMapView(frame: view.bounds, styleURL: customStyleURL)
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        mapView.delegate = self
        mapView.miDelegate = self

        if let venueSlug = self.venueSlug{
            mappedIn.getVenue(venueSlug: venueSlug, completionHandler: {(resultCode, venue) -> Void in
                self.venue = venue
                self.mapView.loadMap(venue: venue!)
            })
        }
    }

    func handleNavigationTapping(space: MiSpace) {
        // TODO: fix highlighting multiple spaces green when selecting multiple start locations consecutively from navigation box 
        if let location = space.locations.first {
            if (startLocation != nil && endLocation != nil) {
                startLocation = nil
                endLocation = nil
                
                if let path = previousPath {
                     mapView.removePath(path: path)
                     previousPath = nil
                 }
                 mapView.clearAllPolygonStyles()
            }
            if (startLocation == nil) {
                onLocationUpdate(navigationLocation: NavigationLocation.start, location: location)
            } else if (endLocation == nil) {
                onLocationUpdate(navigationLocation: NavigationLocation.end, location: location)
            }
        }
    }

    //changes visibility of layers so only 3D layers are visible and allows map to be tilted
    private func show3DLayers() {
        mapView.show3DLayers()
        mapView.isPitchEnabled = true
    }

    //changes visibility of layers so only 2D layers are visible and disables map tilt
    private func hide3DLayers() {
        mapView.hide3DLayers()
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
    func onMapLoaded(status: MiMapStatus) {
        self.mapView.focusOnCurrentLevel()
    }
    
    func onManipulateCamera(gesture: MiGestureType) {
        switch gesture {
        case .PAN:
            recenter.isHidden = false
        case .PINCH: break
        @unknown default:
            assert(false)
        }
    }

    func onTapNothing() {
        mapView.clearAllPolygonStyles()
    }

    func didTapSpace(space: MiSpace) -> Bool {
        self.handleNavigationTapping(space: space)
        return true
    }

    func onTapCoordinates(point: CLLocationCoordinate2D) {
        if addOverlaysOn.isOn {
            if let currentLevel = mapView.currentLevel {
                let view = createLabelView(text: "1")
                let overlay = MiOverlay(coordinates: point, level: currentLevel, view: view)
                mapView.displayOverlays(overlays: [overlay])
            }
        }
    }

    func didTapOverlay(overlay: MiOverlay) -> Bool {
        if !addOverlaysOn.isOn {
            mapView.removeOverlays(overlays: [overlay])
        }
        return true
    }

    func createLabelView(text: String, padding: Double = 5) -> UIView {
        let padding = CGFloat(padding)
        let parent = UIView()
        let view = UIView()
        parent.addSubview(view)
        parent.backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = padding * 2

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = label.font.withSize(10)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.blue
        label.text = text
        view.addSubview(label)
        label.sizeToFit()
        if label.bounds.size.width < padding * 2 {
            label.bounds.size.width = padding * 4
        }

        view.topAnchor.constraint(equalTo: label.topAnchor, constant: -padding).isActive = true
        view.rightAnchor.constraint(equalTo: label.rightAnchor, constant: padding).isActive = true
        view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: padding).isActive = true
        view.leftAnchor.constraint(equalTo: label.leftAnchor, constant: -padding).isActive = true
        view.bounds.size.width = label.bounds.size.width + 2 * padding
        view.bounds.size.height = label.bounds.size.height + 2 * padding

        let path = UIBezierPath()
        let height = view.bounds.size.height
        // Draw arrow
        path.move(to: CGPoint(x: view.frame.size.width/2 - padding, y: height))
        path.addLine(to: CGPoint(x: view.frame.size.width/2 + padding, y: height))
        path.addLine(to: CGPoint(x: view.frame.size.width/2, y: height + padding*2))
        path.addLine(to: CGPoint(x: view.frame.size.width/2 - padding, y: height))
        path.close()

        let shape = CAShapeLayer()
        shape.removeFromSuperlayer()
        shape.backgroundColor = UIColor.clear.cgColor
        shape.fillColor = UIColor.white.cgColor
        shape.path = path.cgPath
        view.layer.addSublayer(shape)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
        parent.bounds.size.width = view.bounds.size.width
        parent.bounds.size.height = view.bounds.size.height + padding * 2

        return parent
    }

    func onLevelChange(level: MiLevel) {
        mapView.addLocationSmartLabels(level: level)
        mapView.focusOnCurrentLevel(padding: 50)
    }
}

extension MapViewController: MGLMapViewDelegate {
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView.showsUserLocation = true
    }
}

extension MapViewController: NavigationDelegate {
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
        
        startButton.setAttributedTitle(NSAttributedString(string: startLocation?.name ?? "Enter your starting location", attributes: [NSAttributedString.Key.foregroundColor: startLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)
        
        endButton.setAttributedTitle(NSAttributedString(string: endLocation?.name ?? "Enter your destination", attributes: [NSAttributedString.Key.foregroundColor: endLocation != nil ? UIColor.black : UIColor.lightGray]), for: .normal)
        
        var directions: (MiDirections, MiPath)? = nil
        if let startLocation = startLocation, let endLocation = endLocation {
            directions = mapView.createNavigationPath(from: startLocation, to: endLocation, pathWidth: 10, pathColor: UIColor.blue)
            previousPath = directions?.1
        }
        
        let startSpaces = directions?.0.path.first?.spaces.filter { space in
            startLocation?.spaces.contains(space) ?? false
        }
        if let startSpace = startSpaces?.first {
            highlightPathSpace(navigationLocation: .start, space: startSpace)
            if let currentLevel = directions?.0.path.first?.level {
                mapView.setLevel(level: currentLevel)
            }
            mapView.focusOn(focusable: startSpace, heading: 0, over: 1000.0)
        }
        
        let endSpaces = directions?.0.path.last?.spaces.filter { space in
            endLocation?.spaces.contains(space) ?? false
        }
        highlightPathSpace(navigationLocation: .end, space: endSpaces?.first)
        
    }
    
    func highlightPathSpace(navigationLocation: NavigationLocation, space: MiSpace?) {
        if let space = space {
            let highlight: MiHighlightProperties
            let outline: MiOutlineProperties
            switch navigationLocation {
            case .start:
                highlight = MiHighlightProperties(color: UIColor.init(red: 0.0, green: 1.0, blue: 50.0/255.0, alpha: 1.0), opacity: 1.0)
                outline = MiOutlineProperties(color: UIColor.init(red: 0.0, green: 140.0/255.0, blue: 20.0/255.0, alpha: 1.0), width: 5.0, opacity: 1.0)
                break
            case .end:
                highlight = MiHighlightProperties(color: UIColor.init(red: 1.0, green: 218.0/255.0, blue: 185.0/255.0, alpha: 1.0), opacity: 1.0)
                outline = MiOutlineProperties(color: UIColor.init(red: 220.0/255.0, green: 20.0/255.0, blue: 60.0/255.0, alpha: 1.0), width: 5.0, opacity: 1.0)
            }
            selectSpace(space: space, highlightProperty: highlight, outlineProperty: outline)
        }
    }
    
    func selectSpace(space: MiSpace, highlightProperty: MiHighlightProperties, outlineProperty: MiOutlineProperties) {
        mapView.setPolygonColor(id: space.id, styleProperties: highlightProperty)
        mapView.setPolygonOutline(id: space.id, styleProperties: outlineProperty)
        selectedPolygons.insert(space.id)
    }
}
