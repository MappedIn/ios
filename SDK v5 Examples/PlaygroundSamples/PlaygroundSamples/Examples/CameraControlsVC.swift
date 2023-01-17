//
//  CameraControlsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class CameraControlsVC: UIViewController {
    // Views
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
        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: (view.frame.height / 3) * 2))
        mapView?.delegate = self
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ))
        }
        
        setupControlsView()
    }
    
    func setupControlsView() {
        let controlsStackView = UIStackView()
        view.addSubview(controlsStackView)
        controlsStackView.axis = .vertical
        controlsStackView.distribution = .fillEqually
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controlsStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        controlsStackView.heightAnchor.constraint(equalToConstant: view.frame.height / 3).isActive = true
        controlsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
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
}

extension CameraControlsVC: MPIMapViewDelegate {
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
