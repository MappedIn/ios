//
//  FlatLabelsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class FlatLabelsVC: UIViewController, MPIMapViewDelegate {

    let mainStackView = UIStackView()
    var mapView: MPIMapView?
    let flatLabelStyleButton = UIButton(type: .system)
    var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMainStackView()
        setupMapView()
        setupButton()
    }
    
    func setupMainStackView() {
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.alignment = .fill
    }
    
    func setupMapView() {
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
        if let mapView = mapView {
            mainStackView.addArrangedSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ), 
                  showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: false, multiBufferRendering: true, xRayPath: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
        }
        
        loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
        }
    }
    
    func setupButton() {
        let flatLabelStackView = UIStackView()
        flatLabelStackView.axis = .horizontal
        flatLabelStackView.alignment = .center
        flatLabelStackView.spacing = 8
        flatLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        flatLabelStackView.isLayoutMarginsRelativeArrangement = true

        let styleLabel = UILabel()
        styleLabel.text = "Style: "
        styleLabel.translatesAutoresizingMaskIntoConstraints = false
        flatLabelStackView.addArrangedSubview(styleLabel)

        flatLabelStyleButton.setTitle("Default", for: .normal)
        flatLabelStyleButton.menu = populateStyleMenu()
        flatLabelStyleButton.showsMenuAsPrimaryAction = true
        flatLabelStyleButton.translatesAutoresizingMaskIntoConstraints = false
        flatLabelStackView.addArrangedSubview(flatLabelStyleButton)
        flatLabelStackView.addArrangedSubview(UIView())
        mainStackView.addArrangedSubview(flatLabelStackView)
    }
    
    // Populates the Style Selection menu.
    func populateStyleMenu() -> UIMenu {
        var menuActions: [UIAction] = []

        let defaultStyle = UIAction(title: "Default") { (action) in
            //Remove and re-add all Flat Labels using the default style.
            self.mapView?.flatLabelManager.removeAll()
            self.mapView?.flatLabelManager.labelAllLocations()
            self.flatLabelStyleButton.setTitle("Default", for: .normal)
        }
        
        menuActions.append(defaultStyle)
        
        let smallRedStyle = UIAction(title: "Small Red") { (action) in
            //Remove and re-add all Flat Labels using a custom style.
            let flatLabelAppearance = MPIOptions.FlatLabelAppearance(color: "#e31a0b", fontSize: 4)
            let flatLabelLocations = MPIOptions.FlatLabelAllLocations(appearance: flatLabelAppearance)
            self.mapView?.flatLabelManager.removeAll()
            self.mapView?.flatLabelManager.labelAllLocations(options: flatLabelLocations)
            self.flatLabelStyleButton.setTitle("Small Red", for: .normal)
        }
        
        menuActions.append(smallRedStyle)
        
        let mediumBlueStyle = UIAction(title: "Medium Blue") { (action) in
            //Remove and re-add all Flat Labels using a custom style.
            let flatLabelAppearance = MPIOptions.FlatLabelAppearance(color: "#0a0dbf", fontSize: 8)
            let flatLabelLocations = MPIOptions.FlatLabelAllLocations(appearance: flatLabelAppearance)
            self.mapView?.flatLabelManager.removeAll()
            self.mapView?.flatLabelManager.labelAllLocations(options: flatLabelLocations)
            self.flatLabelStyleButton.setTitle("Medium Blue", for: .normal)
        }
        
        menuActions.append(mediumBlueStyle)
        
        let largePurpleStyle = UIAction(title: "Large Purple") { (action) in
            //Remove and re-add all Flat Labels using a custom style.
            let flatLabelAppearance = MPIOptions.FlatLabelAppearance(color: "#7c08d4", fontSize: 16)
            let flatLabelLocations = MPIOptions.FlatLabelAllLocations(appearance: flatLabelAppearance)
            self.mapView?.flatLabelManager.removeAll()
            self.mapView?.flatLabelManager.labelAllLocations(options: flatLabelLocations)
            self.flatLabelStyleButton.setTitle("Large Purple", for: .normal)
        }
        
        menuActions.append(largePurpleStyle)

        return UIMenu(title: "Flat Label Style", options: .displayInline, children: menuActions);
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
        
        // Zoom in when the map loads to better show the Flat Labels.
        mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: 800.0,  position: mapView?.currentMap?.createCoordinate(latitude: 43.86181934825464, longitude: -78.94672121994297)))
        
        // Enable all Flat Labels with the default style.
        mapView?.flatLabelManager.labelAllLocations()
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
}
