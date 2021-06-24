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
        print("update: ")
        nearestNode = update.nearestNode
        updateBlueDotBanner(blueDotPosition: update)
        print(update.bearing ?? "")
    }

    func onBlueDotStateChange(stateChange: MPIBlueDotStateChange) {
        print("stateChange: ")
//        print(stateChange.name)
        print(stateChange.markerVisibility ?? "")
//        print(stateChange.reason)
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
        if let node = (polygon.entrances?[0]) {
            let markerId = mapView?.createMarker(
                node: node,
                contentHtml: "<div style=\"width: 32px; height: 32px;\"><svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 293.334 293.334\"><g fill=\"#010002\"><path d=\"M146.667 0C94.903 0 52.946 41.957 52.946 93.721c0 22.322 7.849 42.789 20.891 58.878 4.204 5.178 11.237 13.331 14.903 18.906 21.109 32.069 48.19 78.643 56.082 116.864 1.354 6.527 2.986 6.641 4.743.212 5.629-20.609 20.228-65.639 50.377-112.757 3.595-5.619 10.884-13.483 15.409-18.379a94.561 94.561 0 0016.154-24.084c5.651-12.086 8.882-25.466 8.882-39.629C240.387 41.962 198.43 0 146.667 0zm0 144.358c-28.892 0-52.313-23.421-52.313-52.313 0-28.887 23.421-52.307 52.313-52.307s52.313 23.421 52.313 52.307c0 28.893-23.421 52.313-52.313 52.313z\"/><circle cx=\"146.667\" cy=\"90.196\" r=\"21.756\"/></g></svg></div>",
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

    func onDataLoaded(data: MPIData) {
        let rankings: MPIRankings? = data.rankings
        let polygonRank = data.polygons[0].rank
    }

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
        guard let locations = mapView?.venueData?.locations else { return }
        mapView?.getDirections(
            to: MPIDestinationSet(destinations: [locations[4], locations[5], locations[6]]),
            from: locations[7],
            accessible: false
        ) { directions in
            guard let directions = directions else { return }

            // draw the journey
            self.mapView?.journeyManager.draw(
                directions: directions,
                options: MPIOptions.Journey(connectionTemplateString: "<div style=\"font-size: 13px;display: flex; align-items: center; justify-content: center;\"><div style=\"margin: 10px;\">{{capitalize type}} {{#if isEntering}}to{{else}}from{{/if}} {{toMapName}}</div><div style=\"width: 40px; height: 40px; border-radius: 50%;background: blue;display: flex;align-items: center;margin: 5px;margin-left: 0px;justify-content: center;\"><svg height=\"16\" viewBox=\"0 0 36 36\" width=\"16\"><g fill=\"white\">{{{icon}}}</g></svg></div></div>")
            )
            // change the journey step
            for i in 0...2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 15 + Double(5*i)) {
                    self.mapView?.journeyManager.setStep(step: i)
                }
            }
            // clear journey
            DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
                self.mapView?.journeyManager.clear()
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
