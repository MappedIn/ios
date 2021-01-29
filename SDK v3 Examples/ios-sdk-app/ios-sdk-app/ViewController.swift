//
//  ViewController.swift
//  ios-sdk-app
//
//  Created by Tobi Burnett on 2020-12-01.
//

import UIKit
import mappedin_sdk_v3

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate  {

    @IBOutlet weak var locationDetailView: UIView!
    var mapView: MPIMapView?
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeDetail: UITextView!
    @IBOutlet weak var mapListView: UITextField!
    
    @IBOutlet weak var blueDotBanner: UITextView!
    
    var selectedPolygon: MPIPolygon? = nil
    var nearestNode: MPINode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let screenRect = UIScreen.main.bounds
        let screenWidth = screenRect.size.width
        let screenHeight = screenRect.size.height
        
        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        mapView?.delegate = self
        if let mapView = mapView {
            self.view.insertSubview(mapView, belowSubview: mapListView)
            mapView.loadVenue(options: MPIOptions.Init(clientId: "5eab30aa91b055001a68e996", clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1", venue: "mappedin-demo-mall"))
            
        }
        
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
        if let _nearestNode = nearestNode,
           let _selectedPolygon = selectedPolygon {
            mapView?.getDirections(to: _selectedPolygon, from: _nearestNode, accessible: true) { directions in
                self.mapView?.removeAllPaths() { error in
                    self.mapView?.drawPath(path: directions.path)
                }
            }
        }
    }

    func onMapLoaded () -> Void {
        
        mapView?.enableBlueDot()
        if let filepath = Bundle.main.path(forResource: "positions", ofType: "json") {
            let contents = try? String(contentsOfFile: filepath)
            let positionData = contents?.data(using: .utf8)!
            if let positionData = positionData {
                if let positions = try? JSONDecoder().decode([MPIPosition].self, from: positionData) {
                    for (index, position) in positions.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + (0.4*Double(index)) ) {
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
    }
    
    func onPolygonClicked(polygon: MPIPolygon) {
        if let location = polygon.locations?.first {
            selectedPolygon = polygon
            mapView?.focusOn(focusOptions: MPIOptions.Focus(polygons: [polygon]))
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
}

