//
//  ViewController.swift
//  ios-sdk-app
//
//  Created by Tobi Burnett on 2020-12-01.
//

import UIKit
import Mappedin

class ViewController: UIViewController {
    
    @IBOutlet weak var locationDetailView: UIView!
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var followStateButton: UIButton!
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeDetail: UITextView!
    @IBOutlet weak var mapListView: UITextField!
    @IBOutlet weak var blueDotBanner: UITextView!

    var mapView: MPIMapView?
    var selectedPolygon: MPIPolygon?
    var nearestNode: MPINode?
    var venueDataString: String?
    var presentMarkerId: String?
    var defaultRotation: Double?
    var defaultTilt: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        
        // Set up MPIMapView and add to view
        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        // Set up MPIMapView delegate to listen to MPIMapView events
        mapView?.delegate = self
        
        // use showVenue to load map from legacy data
        if let mapView = mapView {
            self.view.insertSubview(mapView, belowSubview: mapListView)
            if let path = Bundle.main.path(forResource: "mappedin-demo-mall", ofType: "json") {
                venueDataString = try? String(contentsOfFile: path)
            }
            if let venueDataString = venueDataString {
                mapView.showVenue(
                    venueResponse: venueDataString,
                    showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: true, backgroundColor: "#CDCDCD")
                ) { error in
                    print(error.debugDescription)
                }
            }
        }
        
        
        // use loadVenue to load map
//        if let mapView = mapView {
//            self.view.insertSubview(mapView, belowSubview: mapListView)
//            // Provide credentials, if using proxy use MPIOptions.Init(venue: "venue_slug", baseUrl: "proxy_url", noAuth: true)
//            mapView.loadVenue(
//                options: MPIOptions.Init(
//                    clientId: "5eab30aa91b055001a68e996",
//                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
//                    venue: "mappedin-demo-mall"
//                )
//            )
//            mapView.loadVenue(
//                options: MPIOptions.Init(
//                    clientId: "597f83ed17c5ba4b59000000",
//                    clientSecret: "7fde2284cf0b19030865977666233276",
//                    venue: "mappedin-demo-mall",
//                    headers: [MPIHeader(name: "customheader", value: "test")]
//                ),
//                showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: true, backgroundColor: "#CDCDCD")
//            )
//        }
        
        storeName.font = UIFont.boldSystemFont(ofSize: 15)
        storeName.numberOfLines = 0
        storeDetail.textContainer.maximumNumberOfLines = 3
        storeDetail.isEditable = false
        blueDotBanner.isEditable = false
        
        createPickerView()
        dismissPickerView()
        locationDetailView.isHidden = true
    }
    
    @IBAction func closeDetailView(_ sender: UIButton) {
        hideLocationView()
    }
    
    @IBAction func onDirectionsButtonClick(_ sender: UIButton) {
        guard let _nearestNode = nearestNode,
              let _selectedPolygon = selectedPolygon
        else { return }

        // Get directions to selected polygon from users nearest node
        mapView?.getDirections(to: _selectedPolygon, from: _nearestNode, accessible: true) { directions in
            // remove custom markers before calling drawJourney
            if let markerId = self.presentMarkerId {
                self.mapView?.removeMarker(id: markerId)
            }
            if let directions = directions {
                self.mapView?.drawJourney(
                    directions: directions,
                    options: MPIOptions.Journey(
                        connectionTemplateString: "<div style=\"font-size: 13px;display: flex; align-items: center; justify-content: center;\"><div style=\"margin: 10px;\">{{capitalize type}} {{#if isEntering}}to{{else}}from{{/if}} {{toMapName}}</div><div style=\"width: 40px; height: 40px; border-radius: 50%;background: green;display: flex;align-items: center;margin: 5px;margin-left: 0px;justify-content: center;\"><svg height=\"16\" viewBox=\"0 0 36 36\" width=\"16\"><g fill=\"white\">{{{icon}}}</g></svg></div></div>",
                        destinationMarkerTemplateString: nil,
                        departureMarkerTemplateString: "",
                        pathOptions: MPIOptions.Path(color: "#CDCDCD", pulseColor: "#000000", displayArrowsOnPath: true),
                        polygonHighlightColor: "orange"
                    )
                )
            }
        }
    }
    
    @IBAction func followStateButtonClick(_ sender: Any) {
        mapView?.blueDotManager.setState(state: MPIState.FOLLOW)
    }
    
    @IBAction func resetCameraClick() {
        guard let rotation = defaultRotation,
              let tilt = defaultTilt
        else { return }

        mapView?.cameraControlsManager.setRotation(rotation: rotation) { _, error in
            guard error == nil else { return }
            // access rotation here
            print(self.mapView?.cameraControlsManager.rotation ?? "")
        }
        mapView?.cameraControlsManager.setTilt(tilt: tilt) { _, error in
            guard error == nil else { return }
            // access tilt here
            print(self.mapView?.cameraControlsManager.tilt ?? "")
        }
    }

    @IBAction func getDirectionToCenterCoordinates(_ sender: Any) {
        mapView?.getNearestNodeByScreenCoordinates(
            x: Int(mapView!.bounds.width/2),
            y: Int(mapView!.bounds.height/2)
        ) { nearestNode in
            guard let _nearestNode = nearestNode,
                  let _selectedPolygon = self.selectedPolygon
            else { return }

            // Get directions to selected polygon from users nearest node
            self.mapView?.getDirections(to: _selectedPolygon, from: _nearestNode, accessible: true) { directions in
                if let markerId = self.presentMarkerId {
                    self.mapView?.removeMarker(id: markerId)
                }
                if let directions = directions {
                    self.mapView?.drawJourney(
                        directions: directions,
                        options: MPIOptions.Journey(
                            pathOptions: MPIOptions.Path(color: "#cdcdcd", pulseColor: "#000000", displayArrowsOnPath: true)
                        )
                    )
                }
            }
        }
    }
    
    func onMapLoaded () {
        // Enable blue dot (need to call updatePosition with correct coordinates to display on map)
        mapView?.enableBlueDot(
            options: MPIOptions.BlueDot(
                allowImplicitFloorLevel: true,
                smoothing: false,
                showBearing: true,
                baseColor: "#2266ff"
            )
        )
        guard let filepath = Bundle.main.path(forResource: "positions", ofType: "json") else { return }
        let contents = try? String(contentsOfFile: filepath)
        guard let positionData = contents?.data(using: .utf8) else { return }
        guard let positions = try? JSONDecoder().decode([MPIPosition].self, from: positionData) else { return }
        for (index, position) in positions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (3 * Double(index))) {
                self.mapView?.updatePosition(position: position)
            }
        }
    }
    
    func hideLocationView() {
        locationDetailView.isHidden = true
        selectedPolygon = nil
        mapView?.clearAllPolygonColors()
        mapView?.clearJourney()
    }
    
    func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        mapListView.inputView = pickerView
        mapListView.tintColor = UIColor.clear
    }
    
    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.action))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        mapListView.inputAccessoryView = toolBar
    }
    
    func distanceLocationToNode(map: MPIMap, latitude: Double, longitude: Double) -> Double? {
        // Create an MPICoordinate from Latitude and Longitude
        let coord = map.createCoordinate(latitude: latitude, longitude: longitude)
        
        guard let p1_x = coord?.x, let p1_y = coord?.y else { return nil }
        guard let p2_x = nearestNode?.x, let p2_y = nearestNode?.y else { return nil }
        // Calculate Distance Between coord and the nearest node
        let xDist = (p2_x - p1_x)
        let yDist = (p2_y - p1_y)
        let mappedinDistance = sqrt(xDist * xDist + yDist * yDist);
        // Convert the distance from Mappedin units to meters
        guard let scale = map.x_scale else { return nil }
        let worldDistance = mappedinDistance*scale
        return worldDistance
    }
    
    @objc func action() {
        view.endEditing(true)
    }
    
}
