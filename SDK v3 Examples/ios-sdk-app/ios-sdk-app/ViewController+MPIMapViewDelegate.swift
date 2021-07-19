//
//  ViewController+MPIMapViewDelegate.swift
//  ios-sdk-app
//
//  Created by Saman Sandhu on 2021-05-28.
//

import UIKit
import Mappedin

extension ViewController: MPIMapViewDelegate {

    func onBlueDotPositionUpdate(update: MPIBlueDotPositionUpdate) {
        // Store a reference of the nearest node to use later when getting directions
        nearestNode = update.nearestNode
        updateBlueDotBanner(blueDotPosition: update)
    }

    func onBlueDotStateChange(stateChange: MPIBlueDotStateChange) {
        print("Blue Dot State Change: \(stateChange.name) \(String(describing: stateChange.markerVisibility))")
    }

    func onMapChanged(map: MPIMap) {
        mapListView.text = map.name

        // Calculate distance between a lat/lon location to the nearestNode
        let distance = distanceLocationToNode(map: map, latitude: 43.5214, longitude: -80.5369)
        print(distance ?? "")
    }

    func onPolygonClicked(polygon: MPIPolygon) {
        guard let location = polygon.locations?.first else { return }
        selectedPolygon = polygon

        // Focus on polygon when clicked
//        mapView?.focusOn(focusOptions: MPIOptions.Focus(polygons: [polygon]))
        mapView?.focusOn(focusOptions: MPIOptions.Focus(nodes: location.nodes))

        // Clear the present marker
        if let markerId = presentMarkerId {
            mapView?.removeMarker(id: markerId)
        }
        // Add a marker on the polygon being clicked
        if let node = (polygon.entrances?[0]), let markerString = markerString {
            let markerId = mapView?.createMarker(
                node: node,
                contentHtml: markerString,
                markerOptions: MPIOptions.Marker(anchor: MPIOptions.MARKER_ANCHOR.TOP)
            )
            if let markerId = markerId {
                presentMarkerId = markerId
            }
        }

        // Clear all polygon colors before setting polygon color to blue
        mapView?.clearAllPolygonColors() { error in
            self.mapView?.setPolygonColor(polygon: polygon, color: "blue")
        }

        storeName.text = location.name
        storeDetail.text = location.description

        if let imageUrl = location.logo?.original,
           let url = URL(string: imageUrl),
           let data = try? Data(contentsOf: url)
        {
            locationImageView.image = UIImage(data: data)
        }

        locationDetailView.frame = self.view.frame
        self.locationDetailView.isHidden = false
    }

    func onNothingClicked() {
        hideLocationView()
    }

    func onBlueDotUpdated(blueDot: MPIBlueDot) {
        // Store a reference of the nearest node to use later when getting directions
//        nearestNode = blueDot.nearestNode
//        updateBlueDotBanner(blueDot: blueDot)
    }

    func onDataLoaded(data: MPIData) {}

    func onFirstMapLoaded() {
        self.onMapLoaded()

        // get default camera state
        defaultRotation = mapView?.cameraControlsManager.rotation
        defaultTilt = mapView?.cameraControlsManager.tilt

        // set camera state
        mapView?.cameraControlsManager.setRotation(rotation: 180)
        mapView?.cameraControlsManager.setTilt(tilt: 0)

        // label all locations to be light on dark
        mapView?.labelAllLocations(
            options: MPIOptions.LabelAllLocations(
                appearance: MPIOptions.LabelAppearance.lightOnDark
            )
        )

        // create a multi-destination journey between 4 sample locations
        guard let locations = mapView?.venueData?.locations, locations.count >= 8 else { return }
        mapView?.getDirections(
            to: MPIDestinationSet(destinations: [locations[4], locations[5], locations[6]]),
            from: locations[7],
            accessible: false
        ) { directions in
            guard let directions = directions else { return }

            // draw the journey
            self.mapView?.journeyManager.draw(
                directions: directions,
                options: MPIOptions.Journey(connectionTemplateString: self.connectionTemplateString)
            )

            let maxSteps = 3
            let startDelay = 15.0
            let stepDelay = 5

            for step in 0...maxSteps {
                // manipulate journey after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(stepDelay * step)) {
                    if step == maxSteps {
                        // change the journey step
                        self.mapView?.journeyManager.clear()
                    } else {
                        // clear journey
                        self.mapView?.journeyManager.setStep(step: step)
                    }
                }
            }
        }
    }

    func updateBlueDotBanner(blueDotPosition: MPIBlueDotPositionUpdate? = nil) {
        blueDotBanner.text = "BlueDot Nearest Node: " + (blueDotPosition?.nearestNode?.id ?? "N/A")
    }

    func onStateChanged (state: MPIState) {
        switch state {
        case .EXPLORE:
            followStateButton.isHidden = false
        case .FOLLOW:
            followStateButton.isHidden = true
        default:
            print("Unhandled case") // should never be reached
        }
    }
}
