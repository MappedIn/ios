//
//  CameraControlsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class CameraControlsVC: UIViewController, MPIMapViewDelegate {
    // Views
    let mainStackView = UIStackView()
    let controlsStackView = UIStackView()
    var mapView: MPIMapView?
    var plusTiltBtn: UIButton?
    var minusTiltBtn: UIButton?
    var plusZoomBtn: UIButton?
    var minusZoomBtn: UIButton?
    var resetBtn: UIButton?
    
    // Defaults
    var defaultTilt: Double?
    var defaultZoom: Double?
    var defaultRotation: Double?
    var defaultPosition: MPIMap.MPICoordinate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMainStackView()
        setupMapView()
        setupControlsStackView()
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
                ))
        }
    }
    
    func setupControlsStackView() {
        mainStackView.addArrangedSubview(controlsStackView)
        controlsStackView.axis = .vertical
        controlsStackView.distribution = .fillEqually
        
        // Tilt Buttons
        let tiltStackView = UIStackView()
        tiltStackView.distribution = .fillEqually
        controlsStackView.addArrangedSubview(tiltStackView)
        plusTiltBtn = UIButton(type: .system, primaryAction: UIAction { _ in
            let currentTilt = self.mapView?.cameraManager.tilt ?? 0.0
            let delta = Double.pi / 6.0
            self.mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(tilt: currentTilt + delta))
            
        })
        plusTiltBtn?.setTitle("Increase Tilt", for: .normal)
        tiltStackView.addArrangedSubview(plusTiltBtn!)
        
        minusTiltBtn = UIButton(type: .system, primaryAction: UIAction { _ in
            let currentTilt = self.mapView?.cameraManager.tilt ?? 0.0
            let delta = Double.pi / 6.0
            self.mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(tilt: currentTilt - delta))
            
        })
        minusTiltBtn?.setTitle("Decrease Tilt", for: .normal)
        tiltStackView.addArrangedSubview(minusTiltBtn!)
        
        // Zoom Buttons
        let zoomStackView = UIStackView()
        zoomStackView.distribution = .fillEqually
        controlsStackView.addArrangedSubview(zoomStackView)
        plusZoomBtn = UIButton(type: .system, primaryAction: UIAction { _ in
            let currentZoom = self.mapView?.cameraManager.zoom ?? 0.0
            let delta = 800.0
            self.mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: currentZoom - delta))
            
        })
        plusZoomBtn?.setTitle("Zoom In", for: .normal)
        zoomStackView.addArrangedSubview(plusZoomBtn!)
        
        minusZoomBtn = UIButton(type: .system, primaryAction: UIAction { _ in
            let currentZoom = self.mapView?.cameraManager.zoom ?? 0.0
            let delta = 800.0
            self.mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: currentZoom + delta))
            
        })
        minusZoomBtn?.setTitle("Zoom Out", for: .normal)
        zoomStackView.addArrangedSubview(minusZoomBtn!)
        
        // Reset Button
        resetBtn = UIButton(type: .system, primaryAction: UIAction { _ in
            self.mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: self.defaultZoom, tilt: self.defaultTilt, rotation: self.defaultRotation, position: self.defaultPosition))
            
        })
        resetBtn?.setTitle("Reset", for: .normal)
        controlsStackView.addArrangedSubview(resetBtn!)
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        defaultTilt = mapView?.cameraManager.tilt
        defaultZoom = mapView?.cameraManager.zoom
        defaultRotation = mapView?.cameraManager.rotation
        defaultPosition = mapView?.cameraManager.position
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
