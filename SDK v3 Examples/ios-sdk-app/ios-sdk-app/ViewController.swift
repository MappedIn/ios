//
//  ViewController.swift
//  ios-sdk-app
//
//  Created by Tobi Burnett on 2020-12-01.
//

import UIKit
import Mappedin

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate  {
    
    @IBOutlet weak var locationDetailView: UIView!
    var mapView: MPIMapView?
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var followStateButton: UIButton!
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeDetail: UITextView!
    @IBOutlet weak var mapListView: UITextField!
    
    @IBOutlet weak var blueDotBanner: UITextView!
    
    var selectedPolygon: MPIPolygon? = nil
    var nearestNode: MPINode? = nil
    public var venueDataString: String? = nil
    public var presentMarkerId: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        
        //Set up MPIMapView and add to view
        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        //Set up MPIMapView delegate to listen to MPIMapView events
        mapView?.delegate = self
        
        //use showVenue to load map from legacy data
        if let mapView = mapView {
            self.view.insertSubview(mapView, belowSubview: mapListView)
            if let path = Bundle.main.path(forResource: "mappedin-demo-mall", ofType: "json") {
                venueDataString = try? String(contentsOfFile: path)
            }
            if let venueDataString = venueDataString {
                mapView.showVenue(venueResponse: venueDataString, showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: true, backgroundColor: "#CDCDCD"))
            }
        }
        
        //use loadVenue to load map
        //        if let mapView = mapView {
        //            self.view.insertSubview(mapView, belowSubview: mapListView)
        //            //Provide credentials, if using proxy use MPIOptions.Init(venue: "venue_slug", baseUrl: "proxy_url", noAuth: true)
        //            //mapView.loadVenue(options: MPIOptions.Init(clientId: "5eab30aa91b055001a68e996", clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1", venue: "mappedin-demo-mall"))
        //            mapView.loadVenue(options: MPIOptions.Init(clientId: "597f83ed17c5ba4b59000000", clientSecret: "7fde2284cf0b19030865977666233276", venue: "mappedin-demo-mall", headers: [MPIHeader(name: "customheader", value: "test")]), showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: true, backgroundColor: "#CDCDCD"))
        //        }
        
        storeName.font = UIFont.boldSystemFont(ofSize: 15)
        storeName.numberOfLines = 0
        storeDetail.textContainer.maximumNumberOfLines = 3
        storeDetail.isEditable = false
        blueDotBanner.isEditable = false
        
        createPickerView()
        dismissPickerView()
        locationDetailView.isHidden = true
        followStateButton.layer.cornerRadius = 5
        followStateButton.clipsToBounds = true
    }
    
    @IBAction func closeDetailView(_ sender: UIButton) {
        hideLocationView()
    }
    
    @IBAction func onDirectionsButtonClick(_ sender: UIButton) {
        if let _nearestNode = nearestNode,
           let _selectedPolygon = selectedPolygon {
            //Get directions to selected polygon from users nearest node
            mapView?.getDirections(to: _selectedPolygon, from: _nearestNode, accessible: true) { directions in
                //remover custom markers before calling drawJourney
                if let markerId = self.presentMarkerId {
                    self.mapView?.removeMarker(id: markerId)
                }
                self.mapView?.drawJourney(directions: directions,
                                          options: MPIOptions.Journey(connectionTemplateString: "<div style=\"font-size: 13px;display: flex; align-items: center; justify-content: center;\"><div style=\"margin: 10px;\">{{capitalize type}} {{#if isEntering}}to{{else}}from{{/if}} {{toMapName}}</div><div style=\"width: 40px; height: 40px; border-radius: 50%;background: green;display: flex;align-items: center;margin: 5px;margin-left: 0px;justify-content: center;\"><svg height=\"16\" viewBox=\"0 0 36 36\" width=\"16\"><g fill=\"white\">{{{icon}}}</g></svg></div></div>", destinationMarkerTemplateString: nil, departureMarkerTemplateString: "", pathOptions: MPIOptions.Path(color: "#CDCDCD", pulseColor: "#000000", displayArrowsOnPath: true), polygonHighlightColor: "orange"))
            }
        }
    }
    
    @IBAction func followStateButtonClick(_ sender: Any) {
        mapView?.blueDotManager.setState(state: MPIState.FOLLOW)
    }
    
    @IBAction func getDirectionToCenterCoordinates(_ sender: Any) {
        mapView?.getNearestNodeByScreenCoordinates(x: Int(mapView!.bounds.width/2), y: Int(mapView!.bounds.height/2)) { nearestNode in
            if let _nearestNode = nearestNode,
               let _selectedPolygon = self.selectedPolygon {
                //Get directions to selected polygon from users nearest node
                self.mapView?.getDirections(to: _selectedPolygon, from: _nearestNode, accessible: true) { directions in
                    if let markerId = self.presentMarkerId {
                        self.mapView?.removeMarker(id: markerId)
                    }
                    self.mapView?.drawJourney(directions: directions, options: MPIOptions.Journey(pathOptions: MPIOptions.Path(color: "#cdcdcd", pulseColor: "#000000", displayArrowsOnPath: true)))
                }
            }
        }
    }
    
    func onMapLoaded () -> Void {
        //Enable blue dot (need to call updatePosition with correct coordinates to display on map)
        mapView?.enableBlueDot(options: MPIOptions.BlueDot(allowImplicitFloorLevel: true, smoothing: false, showBearing: true))
        if let filepath = Bundle.main.path(forResource: "positions", ofType: "json") {
            let contents = try? String(contentsOfFile: filepath)
            let positionData = contents?.data(using: .utf8)!
            if let positionData = positionData {
                if let positions = try? JSONDecoder().decode([MPIPosition].self, from: positionData) {
                    for (index, position) in positions.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + (3*Double(index)) ) {
                            self.mapView?.updatePosition(position: position)
                        }
                    }
                    
                }
            }
        }
    }
    
    func hideLocationView() {
        self.locationDetailView.isHidden = true
        selectedPolygon = nil
        mapView?.clearAllPolygonColors()
        mapView?.clearJourney()
    }
    
    
    //Map dropdown
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mapView?.venueData?.maps.count ?? 0
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mapView?.venueData?.maps[row].name ?? ""
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let selectedMap = mapView?.venueData?.maps[row] {
            mapView?.setMap(map: selectedMap)
        }
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
    
    @objc func action() {
        view.endEditing(true)
    }
    
}


extension ViewController: MPIMapViewDelegate {
    
    func onMapChanged(map: MPIMap) {
        mapListView.text = map.name
        
        // Create an MPICoordinate from Latitude and Longitude
        let coord = map.createCoordinate(latitude: 43.5214, longitude: -80.5369)
//        if let coordX = coord?.x, let coordY = coord?.y {
//            print(coordX)
//            print(coordY)
//        }
    }
    
    func onPolygonClicked(polygon: MPIPolygon) {
        if let location = polygon.locations?.first {
            selectedPolygon = polygon
            
            //Focus on polygon when clicked
            //            mapView?.focusOn(focusOptions: MPIOptions.Focus(polygons: [polygon]))
            mapView?.focusOn(focusOptions: MPIOptions.Focus(nodes: location.nodes))
            
            //Clear the present marker
            if let markerId = presentMarkerId {
                mapView?.removeMarker(id: markerId)
            }
            //Add a marker on the polygon being clicked
            if let node = (polygon.entrances?[0]) {
                let markerId = mapView?.createMarker(node: node,
                                                     contentHtml: "<div style=\"width: 32px; height: 32px;\"><svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 293.334 293.334\"><g fill=\"#010002\"><path d=\"M146.667 0C94.903 0 52.946 41.957 52.946 93.721c0 22.322 7.849 42.789 20.891 58.878 4.204 5.178 11.237 13.331 14.903 18.906 21.109 32.069 48.19 78.643 56.082 116.864 1.354 6.527 2.986 6.641 4.743.212 5.629-20.609 20.228-65.639 50.377-112.757 3.595-5.619 10.884-13.483 15.409-18.379a94.561 94.561 0 0016.154-24.084c5.651-12.086 8.882-25.466 8.882-39.629C240.387 41.962 198.43 0 146.667 0zm0 144.358c-28.892 0-52.313-23.421-52.313-52.313 0-28.887 23.421-52.307 52.313-52.307s52.313 23.421 52.313 52.307c0 28.893-23.421 52.313-52.313 52.313z\"/><circle cx=\"146.667\" cy=\"90.196\" r=\"21.756\"/></g></svg></div>",
                                                     markerOptions: MPIOptions.Marker(anchor: MPIOptions.MARKER_ANCHOR.TOP))
                if let markerId = markerId {
                    presentMarkerId = markerId
                }
            }
            
            //Clear all polygon colors before setting polygon color to blue
            mapView?.clearAllPolygonColors() { error in
                self.mapView?.setPolygonColor(polygon: polygon, color: "blue")
            }
            
            
            storeName.text = location.name
            storeDetail.text = location.description
            
            let imageUrl = (location.logo?.original)
            if (imageUrl != nil) {
                let url = URL(string: imageUrl!)
                let data = try? Data(contentsOf: url!)
                locationImageView.image = UIImage(data: data!)
            }
            
            locationDetailView.frame = self.view.frame
            self.locationDetailView.isHidden = false
        }
    }
    
    func onNothingClicked() {
        hideLocationView()
    }
    
    func onBlueDotUpdated(blueDot: MPIBlueDot) {
        //Store a reference of the nearest node to use later when getting directions
        nearestNode = blueDot.nearestNode
        updateBlueDotBanner(blueDot: blueDot)
    }
    
    func onDataLoaded(data: MPIData) {
        return
    }
    
    func onFirstMapLoaded() {
        self.onMapLoaded()
    }
    
    func updateBlueDotBanner(blueDot: MPIBlueDot? = nil) {
        blueDotBanner.text = "BlueDot Nearest Node: " + (blueDot?.nearestNode.id ?? "N/A")
    }
    
    func onStateChanged (state: MPIState) {
        if (state.rawValue == "EXPLORE") {
            followStateButton.isHidden = false
        } else if (state.rawValue == "FOLLOW") {
            followStateButton.isHidden = true
        }
    }
}
