//
//  VenueMapViewController.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-09.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Mappedin
import UIKit
import CoreLocation

// A class is needed to control the behavior of the MapView
class MapViewController: UIViewController {
    @IBOutlet private var mapView: MapView!

    // Wayfinding views
    @IBOutlet weak var topNavigation: RoundView!
    @IBOutlet weak var topNavigationContainer: ContainerView!
    @IBOutlet weak var TopNavigationNotificationView: ContainerView!
    @IBOutlet weak var bottomNavigation: RoundView!
    @IBOutlet weak var bottomNavigationContainer: ContainerView!
    @IBOutlet weak var floorSelectorTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var floorSelectorContainer: ContainerView!
    @IBOutlet weak var floorSelectorContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var floorSelectorContainerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var venueSelectorContainer: ContainerView!
    @IBOutlet weak var disabledInteractionView: UIView!
    @IBOutlet weak var actionPromptContainer: ContainerView!
    @IBAction func closeSearchView(_ sender: Any) {
        searchView?.cancelSearchBar()
    }
    @IBOutlet weak var searchDisabledInteractionView: UIView!
    
    // Buttons
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var accessibilityButton: UIButton!
    @IBOutlet weak var accessibilityView: RoundView!
    
    @IBOutlet weak var venueSelectorButton: UIButton!
    private var isVenueSelectorDisplayed: Bool = false
    @IBAction func onVenueSelectorButtonClick(_ sender: UIButton) {
        if sender == venueSelectorButton && !isVenueSelectorDisplayed {
            self.searchDisabledInteractionView.isHidden = true
            self.disabledInteractionView.isHidden = false
            
            self.venueSelectorCollapsedConstraint.isActive = false
            self.venueSelectorExpandedConstraint.isActive = true
            
            searchView?.closeSearchBar()
            self.isVenueSelectorDisplayed = true
            UIView.animate (
                withDuration: 0.4,
                animations: {}
            )
        }
        else if sender == venueSelectorButton && isVenueSelectorDisplayed {
            self.collapseVenueSelector()
        }
    }
    // Controls the height of the top and bottom view panes
    @IBOutlet weak var topHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!

    // This is important, The Venue's will return children from many calls, all
    // of these children contain a link back to the parent, this is maintained
    // as a weak link and dropping the parent will cause the entire
    // data structure to drop
    private var venue: Venue?
    
    private var mapDictionary = [String: Map]()
    private var venueDictionary = [String: VenueListing]()
    
    @IBOutlet weak var venueSelectorExpandedConstraint: NSLayoutConstraint!
    @IBOutlet weak var venueSelectorCollapsedConstraint: NSLayoutConstraint!
    
    var floorSelectionView: FloorSelectionView?
    var venueSelectionView: VenueSelectorView?

    // The venue can hold 1 to any number of maps, but to keep this simple
    // we are only going to use the first map.
    private var map: Map? {
        willSet(new) {
            if let new = new, new !== map {
                self.mapView.setMap(new)
                self.floorSelectionView?.setCurrentFloor(map: new)
                
                switch state {
                    case .showStoreInfo(let polygon):
                        if polygon.map == new {
                            highlight(polygon: polygon, over: 0)
                            guard let start = self.startingLocation else {break}
                            highlight(navigatable: start)
                        }
                        break
                    case .pathSelect(let path):
                        if path.to.getMap() == new {
                            highlight(navigatable: path.to, over: 0)
                            guard let start = self.startingLocation else {break}
                            highlight(navigatable: start)
                            
                        }
                        break
                    case .navigation(let nav):
                        if nav.to.getMap() == new {
                            highlight(navigatable: nav.to, over: 0)
                            guard let start = self.startingLocation else {break}
                            highlight(navigatable: start)
                        }
                        break
                    default:
                        break
                }
            }
        }
    }
    private var mainFloor: Map?

    // Keeps track of the users current position on the map
    private var isUsingUserLocation = false
    private var startingLocation: Navigatable?
    private var destinationLocation: Navigatable?
    private var iAmHereCoordinate: Coordinate?
    private var iAmHereHeading: Radians = 0
    private var distanceTestCoordinate: Coordinate?

    // Global overlay object for path previews and wayfinding
    private var destinationOverlay: ImageOverlay?
    private var overlaysOnMap: [Coordinate:OverlayWrapper] = [:]
    
    struct OverlayWrapper {
        let name: String
        let image: ImageOverlay
        var sibling: Coordinate?
    }
    
    // Map elements necessary for displaying user location, paths, and direction nodes
    private var cylinder: Cylinder?
    private var arrow: Prism?
    private var path: Path?
    private var directionPoints = [Cylinder]()

    // SCALE is used to scale elements added to the map such as paths.
    // Depending on the size of your venue you may wish to increase or decrease this scale
    private let SCALE: Float = 1;
    // These values will be scaled by the scale set above on viewDidLoad()
    // These values are in meters
    private var TURN_POINT_HEIGHT:Float = 1.5
    private var TURN_POINT_DIAMETER:Float = 2
    private var PATH_WIDTH:Float = 1
    private var PATH_HEIGHT:Float = 1
    private var I_AM_HERE_DIAMETER:Float = 5
    private var I_AM_HERE_HEIGHT:Float = 2
    private var I_AM_HERE_ARROW_HEIGHT: Float = 2
    private var I_AM_HERE_ARROW_COLOR = UIColor.white
    private var I_AM_HERE_CYLINDER_COLOR = Colors.azure
    // Defines points to draw the user arrow
    private var I_AM_HERE_ARROW_POINTS = [
        Vector2(0,1.2),
        Vector2(1.0,-1.2),
        Vector2(0,-0.8),
        Vector2(-1.0,-1.2)
    ]
    private var DISTANCE_FROM_DESTINATION_TO_ARRIVE: Float = 5
    private var DISTANCE_TOO_FAR_FROM_VENUE: Float = 1000
    private var CAMERA_PADDING: Float = 20

    private let OVERHEAD_TILT: Float = 0.1
    private let PERSPECTIVE_TILT: Float = Float.pi/4

    private var accessible: Bool = false

    private var camera = cameraMode.free {
        didSet {
            if camera == .free {
                self.recenterButton.backgroundColor = Colors.black
            } else {
                self.recenterButton.backgroundColor = Colors.green
            }
        }
    }

    // Setup for view controller state machine
    private var state = State.start

    let notAtVenueAlert = UIAlertController(title: "Too Far From Venue", message: "Position based directions are currently unavailable. You can still get directions by selecting your starting location.", preferredStyle: UIAlertController.Style.alert)
    let locationErrorAlert = UIAlertController(title: "Location Error", message: "There was a problem getting directions to this location.", preferredStyle: UIAlertController.Style.alert)
    
    var searchView: SearchView?
    var directionsView: DirectionView?
    var actionPromptView: ActionPromptView?
    var arrivalView: ArrivalNotificationView?

    func setupSearchBar() {
        self.topHeight.constant = 64
        if searchView == nil {
            searchView = SearchView.initFromNib()
        } else {
            searchView?.closeSearchBar()
            searchView!.lastSearch = ""
        }
        if searchView != nil {
            if isUsingUserLocation {
                searchView!.searchBar.placeholder = "enter your destination"
            }
            else {
                searchView!.searchBar.placeholder = "enter your start location"
            }
            
            if venue?.search != nil {
                searchView!.search = venue!.search
            }
            self.topNavigationContainer.childView = searchView
            self.topNavigation.roundSpecifiedCorners(object: topNavigation, radius: 10, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
            self.topNavigationContainer.roundSpecifiedCorners(object: topNavigationContainer, radius: 10, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])

            // Resizes search results if necessary
            searchView!.onResultsNeedSpace = { space in
                self.topHeight.constant = min(169, 64 + CGFloat(space))
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                })
            }
            
            searchView!.onSearchWasSelected = {
                self.searchDisabledInteractionView.isHidden = false
                self.closeLevelSelector()
                
                if self.startingLocation != nil {
                    self.searchView?.searchBar.placeholder = "enter your destination"
                    self.searchView?.lastSearch = ""
                    self.searchView?.searchBar.text = ""
                }
            }
            searchView!.onSearchWasClosed = {
                self.searchDisabledInteractionView.isHidden = true
            }

            // Handles user selection of search results
            searchView!.onSelected = { location in
                // Checks to see that there is a polygon attached to the location.
                guard let polygon = location.polygons.makeIterator().next() else {return}
                self.backButton.isHidden = false

                self.searchView!.searchBar.text = location.name
                // Finds closest polygon belonging to selected amenities or locations
                // (necessary when there are multiple per map)
                var closestPoly = polygon
                var polygons = [Polygon]()
                for poly in location.polygons {
                    polygons.append(poly)
                    self.highlight(polygon: poly)
                    if let coords = self.iAmHereCoordinate {
                        if let distance = coords.getDirections(to: poly, accessible: self.accessible)?.distance,
                            distance < (coords.getDirections(to: closestPoly, accessible: self.accessible)?.distance)! {
                            closestPoly = poly
                        }
                    }
                }
                
                let polygonIsStartingLocation = self.isPolygonSameAsNavigatable(navigatable: self.startingLocation, polygon: closestPoly)
                if !self.isUsingUserLocation {
                    if self.startingLocation == nil {
                        self.startingLocation = closestPoly
                        self.camera = .free
                        self.map = closestPoly.map
                        self.highlight(polygon: closestPoly)
                        self.mapView.frame(
                            closestPoly,
                            padding: self.CAMERA_PADDING,
                            heading: self.mapView.cameraHeading,
                            tilt: self.PERSPECTIVE_TILT,
                            over: 0.6
                        )
                        self.promptChooseDestination()
                    } else {
                        if polygonIsStartingLocation == false {
                            self.checkDestinationLocation(newDestination: closestPoly)
                            self.hidePrompt()
                            self.map = closestPoly.map
                            self.changeState(next: .showStoreInfo(polygon))
                        }
                        else {
                            // take user back to floor of start polygon if they switched floors
                            self.map = closestPoly.map
                        }
                        self.highlight(navigatable: self.startingLocation!)
                        self.mapView.frame(
                            closestPoly,
                            padding: self.CAMERA_PADDING,
                            heading: self.mapView.cameraHeading,
                            tilt: self.PERSPECTIVE_TILT,
                            over: 0.6
                        )
                    }
                } else {
                    // Advances to store info state and frames the camera
                    self.checkDestinationLocation(newDestination: closestPoly)
                    self.map = closestPoly.map
                    self.changeState(next: State.showStoreInfo(closestPoly))
                }
            }
        }
    }

    func setupDirectionsView() {
        if directionsView == nil {
            directionsView = DirectionView.initFromNib()
        }
        if directionsView != nil {
            directionsView!.arrivedAtDestination = false
            directionsView!.nextButton.transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi))
            self.topHeight.constant = 62
            self.topNavigation.roundSpecifiedCorners(object: topNavigation, radius: 0, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
            self.topNavigationContainer.roundSpecifiedCorners(object: topNavigationContainer, radius: 0, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
            self.accessibilityView.isHidden = false

            self.topNavigationContainer.childView = directionsView!

            directionsView!.onNextPressed = { [unowned self] in
                self.camera = .follow
                self.nextNavigation()
                self.closeLevelSelector()
            }

            directionsView!.onPeviousPressed = { [unowned self] in
                self.camera = .follow
                self.previousNavigation()
                self.closeLevelSelector()
            }

            directionsView!.onClose = { [unowned self] in
                self.camera = .free
                self.changeState(next: .start)
            }
        }
    }
}

// MARK: - State Machine
extension MapViewController {
    private enum State {
        case start
        case showStoreInfo(Polygon)
        case pathSelect(PathSelectState)
        case navigation(NavigationState)
    }

    private enum cameraMode {
        case follow
        case free
    }

    private func setUpPrompt() {
        actionPromptContainer?.isHidden = false
        floorSelectorTopConstraint.constant = 128
        if actionPromptView == nil {
            self.actionPromptView = ActionPromptView.initFromNib()
            self.actionPromptContainer.childView = self.actionPromptView!
        }
    }

    private func hidePrompt() {
        actionPromptContainer?.isHidden = true
        floorSelectorTopConstraint.constant = 20
    }

    private func promptChooseStart() {
        setUpPrompt()
        let line = NSMutableAttributedString()
        line.append(NSAttributedString(string: "Choose your "))
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        line.append(NSAttributedString(
            string: "starting location",
            attributes: attrs
        ))
        line.append(NSAttributedString(string: " by searching or tapping the map"))
        actionPromptView?.actionPromptMessage.attributedText = line
        actionPromptView?.actionPromptIcon.image = UIImage(named: "Starting Location")
    }

    private func promptChooseDestination() {
        setUpPrompt()
        let line = NSMutableAttributedString()
        line.append(NSAttributedString(string: "Now, choose your "))
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        line.append(NSAttributedString(
            string: "destination",
            attributes: attrs
        ))
        line.append(NSAttributedString(string: " by searching or tapping the map"))
        actionPromptView?.actionPromptMessage.attributedText = line
        actionPromptView?.actionPromptIcon.image = UIImage(named: "Destination Location")
        destinationLocation = nil
    }

    //Recenter camera on the user's current map
    private func resetCamera() {
        if let map = self.map {
            self.mapView.frame(map, heading: mapView.cameraHeading, tilt: Float.pi/4, over: 1.0)
        }
    }
    
    private func closeLevelSelector() {
        self.floorSelectionView?.collapseLevelSelector()
        self.isFloorSelectorExpanded(isExpanded: false)
    }

    // Handles initial app state:
    // Checks that a user position is available
    // and advances to explore state
    private func toStart() {
        // Setting up UI for this state
        self.backButton.isHidden = true
        self.bottomNavigationContainer.childView = nil
        self.bottomHeight.constant = 0
        self.accessibilityView.isHidden = true
        setupSearchBar()
        searchView?.searchBar.text = ""

        if !isUsingUserLocation {
            self.promptChooseStart()
        }
        
        // If a starting location is already chosen, clear the selection
        if startingLocation != nil {
            unhighlight(navigatable: startingLocation!)
        }
        startingLocation = nil
        
        if destinationLocation != nil {
            unhighlight(navigatable: destinationLocation!)
        }
        destinationLocation = nil

        if self.destinationOverlay != nil {
            self.mapView.remove(destinationOverlay!)
        }
        destinationOverlay = nil

        if (cylinder == nil || self.arrow == nil) && iAmHereCoordinate != nil {
            self.cylinder = Cylinder(position: iAmHereCoordinate!, diameter: I_AM_HERE_DIAMETER, height: I_AM_HERE_HEIGHT, color: I_AM_HERE_CYLINDER_COLOR)
            self.arrow = Prism(position: iAmHereCoordinate!, heading: self.iAmHereHeading, points: self.I_AM_HERE_ARROW_POINTS, height: I_AM_HERE_ARROW_HEIGHT, color: I_AM_HERE_ARROW_COLOR)
        }
        
        if let position = iAmHereCoordinate, let testCoord = distanceTestCoordinate {
            if position.meters(from: testCoord) < DISTANCE_TOO_FAR_FROM_VENUE {
                if camera == .follow {
                    self.mapView.frame(
                        position,
                        padding: CAMERA_PADDING,
                        heading: iAmHereHeading,
                        tilt: PERSPECTIVE_TILT,
                        over: 0.6
                    )
                } else {
                    resetCamera()
                }
            } else {
                resetCamera()
            }
        } else {
            resetCamera()
        }
    }

    private func toStoreInfo() {
        guard let destination = self.destinationLocation else { return }
            checkDestinationLocation(newDestination: destination)
        // UI Setup
        let storeView = StoreInfoView.initFromNib()
        storeView.store = destination
        self.bottomNavigationContainer.childView = storeView
        self.bottomHeight.constant = 124

        setupSearchBar()
        searchView?.searchBar.text = destination.name()
        
        if destination.navigatableCoordinates.first != nil {
            if self.map != destination.getMap() {
                self.map = destination.getMap()
            }
            self.camera = .free
            self.mapView.frame(
                destination.navigatableCoordinates,
                padding: CAMERA_PADDING,
                heading: self.mapView.cameraHeading,
                tilt: Float.pi/4,
                over: 0.6
            )
        }
        
        if self.cylinder != nil {
            if isUsingUserLocation {
                mapView.add(self.cylinder!)
                mapView.add(self.arrow!)
            }
        }

        // Handles user tapping a polygon on the map:
        //  - advances state, highlights and frames camera view on the polygon
        storeView.onSelected = { location in
            guard let destination = location.polygons.makeIterator().next() else { return }
            self.destinationLocation = destination
            self.changeState(next: .showStoreInfo(destination))
            self.highlight(navigatable: destination)
            self.displayDestinationIcon(navigatable: destination)
            self.mapView.frame(
                destination,
                padding: self.CAMERA_PADDING,
                heading: self.mapView.cameraHeading,
                tilt: Float.pi/4,
                over: 0.6
            )
        }

        // Handles user requesting directions, advances state to path preview
        //  - sets the camera to follow mode in preperation for navigation,
        //    or focusing back on the user if they cancel wayfinding
        storeView.directionButtonPressed = { [unowned self] in
            if self.isUsingUserLocation {
                if let coords = self.iAmHereCoordinate,
                    self.map != coords.getMap() {
                    self.map = coords.getMap()
                    self.closeLevelSelector()
                }
                if  let coords = self.iAmHereCoordinate,
                    let path = PathSelectState(from: coords, to: destination, accessible: self.accessible) {
                    self.changeState(next: State.pathSelect(path))
                } else {
                    self.present(self.locationErrorAlert, animated: true, completion: nil)
                }
            } else {
                if let start = self.startingLocation?.navigatableCoordinates.first,
                    let destination = self.destinationLocation,
                    let path = PathSelectState(from: start, to: destination, accessible: self.accessible) {
                    self.changeState(next: State.pathSelect(path))
                } else {
                    self.present(self.locationErrorAlert, animated: true, completion: nil)
                }
            }
        }
    }

    private func toPathSelect(state: PathSelectState) {
        guard let destination = self.destinationLocation else { return }
        if destination.navigatableCoordinates.first != self.destinationOverlay?.coordinate {
            checkDestinationLocation(newDestination: destination)
        }
        // UI Setup
        let pathSelectStatus = PathSelectStatus.initFromNib()
        self.bottomHeight.constant = 124
        self.bottomNavigationContainer.childView = pathSelectStatus

        setupSearchBar()
        searchView?.searchBar.text = destination.name()

        pathSelectStatus.destination = destination

        // Handles user requesting directions and advances to wayfinding state
        pathSelectStatus.goButtonPressed = { [unowned self] in
            if self.map != state.from.getMap() {
                self.map = state.from.getMap()
                self.closeLevelSelector()
            }
            if let coords = self.iAmHereCoordinate,
                let nav = NavigationState(from: coords, to: destination, accessible: self.accessible),
                self.isUsingUserLocation {
                self.changeState(next: .navigation(nav))
            } else if let coords = self.startingLocation?.navigatableCoordinates.first,
                let destination = self.destinationLocation,
                let nav = NavigationState(from: coords, to: destination, accessible: self.accessible) {
                self.changeState(next: .navigation(nav))
            }
        }

        if let path = self.path {
            let focus = [path as Focusable]
            var heading = mapView.cameraHeading
            if let position = iAmHereCoordinate, isUsingUserLocation {
                if let vector = state.directions.instructions.last?.coordinate.vector2 {
                    heading = -position.vector2.angle(to: vector)
                }
            }
            self.mapView.frame(
                focus,
                padding: CAMERA_PADDING,
                heading: heading,
                tilt: OVERHEAD_TILT,
                over: 0.6
            )
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        })
    }

    private func toDirections(navigation: NavigationState) {
        camera = .follow
        setupDirectionsView()
        if directionsView != nil {
            self.map = navigation.map
            self.updateNavigationView(navigation: navigation)
            self.bottomHeight.constant = 70
            let status = DirectionStatusView.initFromNib()
            self.bottomNavigationContainer.childView = status
            status.navigation = navigation
            status.closeAction = { [unowned self] in
                self.camera = .free
                self.changeState(next: .start)
            }

            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    private func previousNavigation() {
        switch state {
        case State.navigation(var navigation):
            camera = .follow
            navigation.previous()
            self.map = navigation.map
            updateNavigationView(navigation: navigation)
            state = .navigation(navigation)
            if navigation.currentInstruction?.coordinate != nil {
                if let navigationMap = navigation.currentInstruction?.coordinate.map {
                    self.floorSelectionView?.setCurrentFloor(map: navigationMap)
                    self.map = navigationMap
                }
                
            } else {
                if let activeMap = mapView.activeMap {
                    self.floorSelectionView?.setCurrentFloor(map: activeMap)
                }
            }
        default:
            break
        }
    }

    private func nextNavigation() {
        switch state {
        case .navigation(var navigation):
            camera = .follow
            navigation.next()
            updateNavigationView(navigation: navigation)
            state = .navigation(navigation)
            if navigation.currentInstruction?.coordinate != nil {
                if let navigationMap = navigation.currentInstruction?.coordinate.map {
                    self.floorSelectionView?.setCurrentFloor(map: navigationMap)
                    self.map = navigationMap
                }
            } else {
                if let activeMap = mapView.activeMap {
                    self.floorSelectionView?.setCurrentFloor(map: activeMap)
                }
            }
        default:
            break
        }
    }
    
    // Used to update the navigation view and focus the relevant area of the mapview
    private func updateNavigationView(navigation: NavigationState) {
        if directionsView == nil {
            return
        }

        if let start = self.startingLocation {
            self.highlight(navigatable: start)
        }
        if let destination = self.destinationLocation {
            self.highlight(navigatable: destination)
        }

        if let currentInstruction = navigation.currentInstruction?.coordinate {
            // if there's a current instruction display it on the topView
            directionsView!.distance = navigation.currentDistance
            directionsView!.instruction = navigation.currentInstruction

            self.directionsView?.previousButton.isEnabled = true
            self.directionsView?.nextButton.isEnabled = true

            if self.map != currentInstruction.map {
                self.map = currentInstruction.map
            }

            // If there's a previous instruction change focus and heading to show previous to current instruction.
            if camera == .follow, let prev = navigation.previousInstruction {
                let angleRads = prev.coordinate.vector2.angle(to: currentInstruction.vector2)
                let focus = [prev.coordinate, currentInstruction]
                self.mapView.frame(
                    focus,
                    padding: CAMERA_PADDING,
                    heading: angleRads,
                    tilt: PERSPECTIVE_TILT,
                    over: 0.6
                )
                camera = .free
            } else {
                // If at first instruction, focus on user location / starting location and first instruction.
                if camera == .follow, isUsingUserLocation {
                    recenterCamera((Any).self)
                    self.directionsView?.previousButton.isEnabled = false
                } else if camera == .follow, let position = startingLocation?.navigatableCoordinates.first {
                    let angleRads = position.vector2.angle(to: currentInstruction.vector2)
                    let focus = [position, currentInstruction]
                    self.mapView.frame(
                        focus,
                        padding: CAMERA_PADDING,
                        heading: angleRads,
                        tilt: PERSPECTIVE_TILT,
                        over: 0.6
                    )
                    camera = .free
                }
            }
        } else {
            // If there is no current instruction we are at the end of navigation.
            directionsView!.distance = navigation.currentDistance
            directionsView!.instruction = nil
            directionsView?.nextButton.isEnabled = false

            if camera == .follow, let previous = navigation.previousInstruction?.coordinate,
                let focus = navigation.to.navigatableCoordinates.first {
                let rads = previous.vector2.angle(to: focus.vector2)
                self.mapView.frame(
                    focus,
                    padding: CAMERA_PADDING,
                    heading: rads,
                    tilt: PERSPECTIVE_TILT,
                    over: 0.6
                )
                camera = .free
            } else if camera == .follow, let position = iAmHereCoordinate,
                let focus = navigation.to.navigatableCoordinates.first {
                let rads = position.vector2.angle(to: focus.vector2)
                let focusArray: [Coordinate] = [focus, position]
                self.mapView.frame(
                    focusArray,
                    padding: CAMERA_PADDING,
                    heading: rads,
                    tilt: PERSPECTIVE_TILT,
                    over: 0.6
                )
                camera = .free
            }
        }
    }

    private func cleanUpCurrentState() {
        self.closeLevelSelector()
        searchView?.cancelSearchBar()
        removeElements()
        removeOverlays()
    }

    private func unselect(state: State) {
        cleanUpCurrentState()
        switch state {
        case .showStoreInfo(let polygon):
            for location in polygon.locations {
                unhighlight(location: location)
            }
            break
        case .pathSelect(let path):
            unhighlight(navigatable: path.to)
            break
        case .navigation(let navigation):
            self.TopNavigationNotificationView.isHidden = true
            self.accessibilityView.isHidden = true
            unhighlight(navigatable: navigation.to)
            if let polygon = navigation.from as? Polygon {
                unhighlight(polygon: polygon)
            }
            break
        default:
            break
        }
    }
    
    private func addOverlays(_directions: Directions, overlayObjectsToBeDeleted: inout [Coordinate:ImageOverlay]){
        //assume that all overlays are to be deleted
        for (key,value) in overlaysOnMap{
            overlayObjectsToBeDeleted[key] = value.image
        }
        
        var connectionIcons: [Coordinate: String] = [:]
        var overlaysToRemainOnMap: Set<Coordinate> = []

        for dir in _directions.instructions {
            if dir.action is Mappedin.Directions.Instruction.TakeConnection {
                if let iconName = self.getFloorChangeOverlay(instruction: dir){
                    connectionIcons[dir.coordinate] = iconName
                    overlaysToRemainOnMap.insert(dir.coordinate)
                }
            }
        }
        
        var connectingOverlay:Bool = false
        var previousConnection:Coordinate?

        for coordinate in _directions.path{
            //insert the next overlay from an existing connection
            if(connectingOverlay){
                self.getFloorChangeOverlay(connection: coordinate, previousType: connectionIcons[previousConnection!]!)
                self.overlaysOnMap[coordinate]?.sibling = previousConnection
                self.overlaysOnMap[previousConnection!]?.sibling = coordinate
                overlaysToRemainOnMap.insert(coordinate)
                connectingOverlay = false
            }

            if(connectionIcons[coordinate] != nil){
                previousConnection = coordinate
                connectingOverlay = true
            }
        }
        // the overlays are still valid so we do not delete them
        for coordinate in overlaysToRemainOnMap{
            overlayObjectsToBeDeleted[coordinate] = nil
        }
    }
    
    private func removeOverlays(){
        for overlay in self.overlaysOnMap.values{
            self.mapView.remove(overlay.image)
        }
        self.overlaysOnMap.removeAll()
    }

    private func select(state: State) {
        switch state {
        case .showStoreInfo(_):
            if self.startingLocation != nil {
                highlight(navigatable: self.startingLocation!)
            }
            if self.destinationLocation != nil {
                highlight(navigatable: self.destinationLocation!)
            }
            break
        case .pathSelect(let path):
            if self.map != path.to.getMap(){
                self.map = path.to.getMap()
            }
            updatePath(newDirections: path.directions)
            highlight(navigatable: path.to)
            if self.startingLocation != nil {
                highlight(navigatable: self.startingLocation!)
            }
            if self.destinationLocation != nil {
                highlight(navigatable: self.destinationLocation!)
            }
            
            if camera == .follow,
                let destination = path.directions.instructions.last?.coordinate.vector2,
                let heading = iAmHereCoordinate?.vector.vector2.angle(to: destination) {
                self.map = path.from.getMap()
                self.mapView.frame(
                    self.path!,
                    padding: CAMERA_PADDING,
                    heading: heading,
                    tilt: OVERHEAD_TILT,
                    over: 0.6
                )
            }
            break
        case .navigation(let navigation):
            updatePath(newDirections: navigation.directions)
            highlight(navigatable: navigation.to)
            break
        default:
            break
        }
    }

    private func changeState(next: State) {
        unselect(state: state)
        select(state: next)

        switch next {
        case .start:
            toStart()
            break
        case .showStoreInfo(_):
            if let destination = self.destinationLocation, self.map != destination.getMap() {
                self.map = destination.getMap()
            }
            toStoreInfo()
            break
        case .pathSelect(let state):
            addAllOverlaysOnMap(from: state.from, to: state.to)
            toPathSelect(state: state)
            break
        case .navigation(let navigation):
            addAllOverlaysOnMap(from: navigation.from, to: navigation.to)
            toDirections(navigation: navigation)
        }
        state = next
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        switch state {
        case .pathSelect(_):
            if let destination = self.destinationLocation as? Polygon {
                changeState(next: .showStoreInfo(destination))
            }
            break
        case .navigation(_):
            if let start = self.startingLocation, let destination = self.destinationLocation,
                let startCoord = start.navigatableCoordinates.first,
                let destCoord = destination.navigatableCoordinates.first,
                let path = PathSelectState(from: startCoord, to: destCoord, accessible: self.accessible) {
                changeState(next: .pathSelect(path))
            } else if let position = self.iAmHereCoordinate, let destination = self.destinationLocation,
                let destCoord = destination.navigatableCoordinates.first,
                let path = PathSelectState(from: position, to: destCoord, accessible: self.accessible) {
                camera = .free
                changeState(next: .pathSelect(path))
            }
            break
        default:
            changeState(next: .start)
            break
        }
    }

    @IBAction func accessibilityButtonPressed(_sender: Any) {
        self.accessible = !self.accessible
        if (self.accessible == true) {
            self.accessibilityButton.backgroundColor = Colors.green
        } else {
            self.accessibilityButton.backgroundColor = Colors.black
        }
        if let start = self.startingLocation, let destination = self.destinationLocation,
            let nav = NavigationState(from: start, to: destination, accessible: self.accessible) {
            changeState(next: .navigation(nav))
        }
        if let userPosition = self.iAmHereCoordinate, let destination = self.destinationLocation,
            let nav = NavigationState(from: userPosition, to: destination, accessible: self.accessible) {
            changeState(next: .navigation(nav))
        }

    }

    @IBAction func recenterCamera(_ sender: Any) {
        camera = .follow
        // Make sure we have user positioning and venue data
        if let userPosition = self.iAmHereCoordinate, isUsingUserLocation {
            var tilt = PERSPECTIVE_TILT

            // Check if user is too far from the venue
            if distanceTestCoordinate != nil && userPosition.meters(from: distanceTestCoordinate!) > DISTANCE_TOO_FAR_FROM_VENUE {
                //Display alert if so
                if !notAtVenueAlert.isBeingPresented {
                    self.present(notAtVenueAlert, animated: true, completion: nil)
                }
                //Recenter camera on venue instead of user location
                resetCamera()
                return
            }
            if self.map != userPosition.map {
                self.map = userPosition.map
                if let map = self.map {
                    self.floorSelectionView?.setCurrentFloor(map: map)
                }
                self.closeLevelSelector()
            }
            var focus = [ userPosition as Focusable ]
            switch state {
            case .pathSelect(let path):
                if !isUsingUserLocation {
                    if let path = self.path {
                        focus = [path as Focusable]
                    }
                    if let vector = path.directions.instructions.last?.coordinate.vector2 {
                        iAmHereHeading = -userPosition.vector2.angle(to: vector)
                        tilt = OVERHEAD_TILT
                    }
                }
                break
            case .navigation(var nav):
                // brings the user back to the very first instruction on a recenter click
                while(nav.index != 0) {
                    nav.previous()
                }
                self.directionsView?.instruction = nav.currentInstruction
                self.directionsView?.distance = nav.currentDistance
                self.directionsView?.previousButton.isEnabled = false
                self.state = .navigation(nav)
                break
            default:
                break
            }
            self.mapView.frame(
                focus,
                padding: CAMERA_PADDING,
                heading: iAmHereHeading,
                tilt: tilt,
                over: 0.6
            )
        } else {
            //Recenter camera on venue instead of user location
            resetCamera()
        }
    }

    private func addAllOverlaysOnMap(from:Navigatable, to: Navigatable) {
        if let directions = from.getDirections(to: to, accessible: self.accessible){
            var overlayObjectsToBeDeleted: [Coordinate:ImageOverlay] = [:]
            
            addOverlays(_directions: directions, overlayObjectsToBeDeleted: &overlayObjectsToBeDeleted)
            
            for (coordinate, _) in overlayObjectsToBeDeleted{
                removeIcon(coordinates: coordinate)
            }
        }
    }

    private func removeElements() {
        if self.path != nil {
            mapView.remove(self.path!)
        }
        for point in self.directionPoints {
            mapView.remove(point)
        }
        self.directionPoints = [Cylinder]()
    }
    
    private func collapseVenueSelector() {
        self.isVenueSelectorDisplayed = false

        if self.venue!.maps.count > 1 {
            floorSelectorContainer.isHidden = false
        }
        
        self.venueSelectorExpandedConstraint.isActive = false
        self.venueSelectorCollapsedConstraint.isActive = true
        
        UIView.animate (
            withDuration: 0.4,
            animations: {
                self.venueSelectorContainer.center.x += 250
            },
            completion: { _ in
                self.disabledInteractionView.isHidden = true
                self.searchDisabledInteractionView.isHidden = true
            }
        )
    }
}

// MARK: - View Methods
extension MapViewController {
    override func viewDidLoad() {
        self.mapView.storeLabelsEnable = true
        self.mapView.delegate = self
        self.floorSelectionView = FloorSelectionView.initFromNib()
        self.venueSelectionView = VenueSelectorView.initFromNib()
        self.topNavigation.roundSpecifiedCorners(object: topNavigation, radius: 10, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        self.topNavigationContainer.roundSpecifiedCorners(object: topNavigationContainer, radius: 10, corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        self.venueSelectorButton.roundSpecifiedCorners(object: venueSelectorButton, radius: 10, corners: [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner])
        self.notAtVenueAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.locationErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        TURN_POINT_HEIGHT = TURN_POINT_HEIGHT * SCALE
        TURN_POINT_DIAMETER = TURN_POINT_DIAMETER * SCALE
        PATH_WIDTH = PATH_WIDTH * SCALE
        PATH_HEIGHT = PATH_HEIGHT * SCALE
        I_AM_HERE_DIAMETER = I_AM_HERE_DIAMETER * SCALE
        I_AM_HERE_HEIGHT = I_AM_HERE_HEIGHT * SCALE
        I_AM_HERE_ARROW_HEIGHT = I_AM_HERE_ARROW_HEIGHT * SCALE + 0.1
        I_AM_HERE_ARROW_POINTS = [
            Vector2(0, 1.2 * SCALE),
            Vector2(1.0 * SCALE, -1.2 * SCALE),
            Vector2(0, -0.8 * SCALE),
            Vector2(-1.0 * SCALE, -1.2 * SCALE)
        ]
        DISTANCE_FROM_DESTINATION_TO_ARRIVE = DISTANCE_FROM_DESTINATION_TO_ARRIVE * SCALE
        DISTANCE_TOO_FAR_FROM_VENUE = DISTANCE_TOO_FAR_FROM_VENUE * SCALE
        CAMERA_PADDING = CAMERA_PADDING * SCALE
        
        // this delegate call takes a boolean value as a parameter
        self.floorSelectionView?.onLevelSelectorExpanded = { [unowned self] expanded in
            self.isFloorSelectorExpanded(isExpanded: expanded)
        }
        
        self.floorSelectionView?.onMapSelected = { [unowned self] string in
            self.map = self.mapDictionary[string]!
            if let map = self.map {
                self.floorSelectionView?.setCurrentFloor(map: map)
                self.mapView.frame(map, heading: self.mapView.cameraHeading, tilt: Float.pi/4, over: 1.0)
            }
            if self.startingLocation != nil {
                self.highlight(navigatable: self.startingLocation!)
            }
            if self.destinationLocation != nil {
                self.highlight(navigatable: self.destinationLocation!)
            }
            self.camera = .free
        }
        
        let right = UISwipeGestureRecognizer(target: self, action: #selector(MapViewController.rightSwipe))
        right.direction = .right
        self.venueSelectorContainer.addGestureRecognizer(right)

    }
    
    func isFloorSelectorExpanded(isExpanded: Bool) {
        if isExpanded {
            self.floorSelectorContainerWidth.constant = 240
            self.floorSelectorContainerHeight.constant = self.floorSelectionView?.recommendedHeight ?? 220
        }
        else {
            self.floorSelectorContainerWidth.constant = (self.floorSelectionView?.getFloorLabelWidth() ?? 50) + 33
            self.floorSelectorContainerHeight.constant = 44
        }
    }
    
    @objc
    func rightSwipe() {
        self.collapseVenueSelector()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.loadVenues()
    }
}

// MARK: - Status bar configuration
extension MapViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - setup
extension MapViewController {
    func loadVenues() {
        // This will create a listing of all the Venues that your Mappedin
        // account currently has. If you already know the name of the Venue
        // you want, you can skip this view and integrate this search into
        // the app init

        service!.getVenues()
            .onComplete { venues in
                self.venueSelectorContainer.childView = self.venueSelectionView
                self.venueSelectionView?.setVenues(venueListings: venues)
                
                var VENUE = venues.first
                for venue in venues {
                    self.venueDictionary[venue.name] = venue
                    
                    print(venue.name, venue.slug)
                    if venue.slug == "mappedin-demo-mall" {
                        VENUE = venue
                    }
                }
 
                guard let venue = VENUE else {
                    // try again
                    self.loadVenues()
                    return
                }
                // get first map from venue
                self.loadVenue(venue: venue)
            }.onError { error in
                print("Error: \(error)")

                // try try again
                self.loadVenues()
            }
    }

    // load a venue from the Mappedin server into this view
    func loadVenue(venue: VenueListing) {
        // This will fetch the venue from our API servers, it completes in an
        // asynchronous way. So might need some form of synchronization if
        // your logic is fancier then what is shown.
        //
        // Note: The callback `onComplete` or `OnError` will only execute on
        // the UI thread. this is done as a convince to the API users.
        service!.getVenue(venue).onComplete { venue in
            if self.floorSelectorContainer.childView == nil {
                self.floorSelectorContainer.childView = self.floorSelectionView
            }
            
            // pin the venue
            self.venue = venue

            // The venue can hold 1 to any number of maps. Here we will load the first map and set it
            // as the main floor. If there is a floor 0 it will set the main floor to that floor.
            // If your venue has multiple floors you may want to chose which floor is the main floor
            // and load that map first.
            self.map = self.venue?.maps[0]
            self.mainFloor = self.venue?.maps[0]
            for map in self.venue!.maps {
                if map.floor == 0 {
                    self.mainFloor = map
                    self.map = map
                }
            }
            if (self.venue?.maps.count)! > 1 {
                self.floorSelectorContainer?.isHidden = false
            }
            else {
                self.floorSelectorContainer?.isHidden = true
            }
            
            if self.mapDictionary.count > 0 {
                self.mapDictionary.removeAll()
            }
            for map in venue.maps {
                self.mapDictionary[map.name] = map
            }
            
            self.floorSelectionView?.setCurrentFloor(map: self.map!)
            self.floorSelectionView?.setVenueMaps(maps: venue.maps)
            self.venueSelectionView?.highlightTableViewCell(venueName: self.venue!.name)
            self.isFloorSelectorExpanded(isExpanded: false)
            
            if self.floorSelectorContainer.childView == nil {
                self.floorSelectorContainer.childView = self.floorSelectionView
            }

            if self.map != nil {
                LocationService.shared.delegate = self

                // Set isUsingUserLocation to true to start. isUsingUserLocation will be
                // set to false in updateLocation() if location permission is denied or
                // the user is too far from the venue.
                self.isUsingUserLocation = true
                self.hidePrompt()
                hasDistancePromptBeenDisplayed = false

                LocationService.shared.startUpdatingLocation()
                LocationService.shared.startUpdatingHeading()
                
                // Find an abitrary coordinate at the venue to use to determine if user
                // is too far away to use positioning
                if venue.locations.count > 0 {
                    for location in venue.locations {
                        if location.navigatableCoordinates.count > 0 {
                            self.distanceTestCoordinate = location.navigatableCoordinates[0]
                            break
                        }
                    }
                }
                
                self.toStart()
            } else {
                print("Error: Venue does not have a map")
            }
        }.onError{error in
            print("Error: \(error)")
        }

        service!.getVenue(venue).onError { (err) in
            print(err.localizedDescription)
        }
        
        // delegate call from VenueSelectorView.swift, takes string as a parameter
        self.venueSelectionView?.newVenueSelected = { [unowned self] mapName in
            // collapse the venue selector and hide the level selector
            self.collapseVenueSelector()
            self.closeLevelSelector()
            
            // this delegate code will only execute if the user selects a new venue
            if let newVenue = self.venueDictionary[mapName], newVenue.name != self.venue?.name {
                // If we are switching venues, be sure to unhighlight any polygons first
                if self.startingLocation != nil {
                    self.unhighlight(navigatable: self.startingLocation!)
                }
                self.startingLocation = nil
                
                if self.destinationLocation != nil {
                    self.unhighlight(navigatable: self.destinationLocation!)
                }
                self.destinationLocation = nil
                
                if let destIcon = self.destinationOverlay {
                    self.mapView.remove(destIcon)
                }
                self.destinationOverlay = nil
                self.iAmHereCoordinate = nil
                hasDistancePromptBeenDisplayed = false
                
                // reset the state to start and clear all previous states
                self.changeState(next: State.start)
                self.loadVenue(venue: newVenue)
            }
        }
    }
}

// MARK: - LocationServiceDelegate
// We've provided a basic location service handler, the implementation can be found under LocationService in the Map Services folder

private var hasDistancePromptBeenDisplayed: Bool = false
extension MapViewController: LocationServiceDelegate {
    
    func handleUserTooFarFromVenue(){
        removeIAmHereFromMap()
        if isUsingUserLocation {
            // Too far away to use location, return to Start
            isUsingUserLocation = false
            self.changeState(next: .start)
            if !hasDistancePromptBeenDisplayed && self.presentedViewController == nil {
                hasDistancePromptBeenDisplayed = true
                self.present(notAtVenueAlert, animated: true, completion: nil)
                hasDistancePromptBeenDisplayed = true
            }
        }
    }
    
    func handleUserInRangeOfVenue(){
        addIAmHereOnMap()
        if !isUsingUserLocation {
            isUsingUserLocation = true
        }
        hidePrompt()
    }
    
    
    // This function does a bunch of checks to make sure that the position make sense and is not too far away from the venue
    func validatePositionFromVenue() {
        if let position = iAmHereCoordinate, let testCoord = distanceTestCoordinate {
            if position.meters(from: testCoord) < DISTANCE_TOO_FAR_FROM_VENUE {
                handleUserInRangeOfVenue()
            } else {
                handleUserTooFarFromVenue()
            }
        }
    }

    func addIAmHereOnMap(){
        if (cylinder == nil || self.arrow == nil) && iAmHereCoordinate != nil {
            self.cylinder = Cylinder(position: iAmHereCoordinate!, diameter: I_AM_HERE_DIAMETER, height: I_AM_HERE_HEIGHT, color: I_AM_HERE_CYLINDER_COLOR)
            self.arrow = Prism(position: iAmHereCoordinate!, heading: self.iAmHereHeading, points: self.I_AM_HERE_ARROW_POINTS, height: I_AM_HERE_ARROW_HEIGHT, color: I_AM_HERE_ARROW_COLOR)
        }
        if self.cylinder != nil && self.arrow != nil && iAmHereCoordinate != nil {
            self.mapView.add(self.cylinder!)
            self.mapView.add(self.arrow!)
        }
    }

    func removeIAmHereFromMap(){
        if self.cylinder != nil, self.arrow != nil {
            self.mapView.remove(self.cylinder!)
            self.mapView.remove(self.arrow!)
        }
    }
    
    func moveIAmHere(position:Coordinate, heading:Radians, over:TimeInterval){
        if self.cylinder != nil, self.arrow != nil {
            self.cylinder?.set(position: position, over: over)
            self.arrow?.set(position: position, over: over)
            self.arrow?.set(heading: heading, over: over)
        }
    }

    func updatePath(newDirections: Directions?) {
        guard let directions = newDirections else {
            return
        }
        let newPathPoints = directions.path
        let newPath = Path(points: newPathPoints, width: PATH_WIDTH, height: PATH_HEIGHT, color: Colors.azure)
        mapView.add(newPath)

        if self.path != nil {
            mapView.remove(self.path!)
        }
        self.path = newPath

        var newDirectionPoints = [Cylinder]()
        for dir in directions.instructions {
            newDirectionPoints.append(Cylinder(position: dir.coordinate, diameter: TURN_POINT_DIAMETER, height: TURN_POINT_HEIGHT, color: Colors.white))
        }

        for point in newDirectionPoints {
            mapView.add(point)
        }
        for point in self.directionPoints {
            mapView.remove(point)
        }
        self.directionPoints = newDirectionPoints
    }

    
    // updates the users location on the map
    func updateLocation(currentLocation: CLLocation, locationManager: CLLocationManager) {
        guard let venue = venue else { return }
        
        if let heading = locationManager.heading?.trueHeading {
            self.iAmHereHeading = Float(-1 * heading * .pi / 180)
        } else {
            self.iAmHereHeading = 0
        }
        
        if let level = currentLocation.floor?.level, level < venue.maps.count {
            self.iAmHereCoordinate = Coordinate(location: currentLocation.coordinate, map: venue.maps[level])
        } else {
            self.iAmHereCoordinate =  Coordinate(location: currentLocation.coordinate, map: mainFloor ?? venue.maps[0])
        }
        
        validatePositionFromVenue()

        if isUsingUserLocation {
            guard let currentPosition = self.iAmHereCoordinate else {
                    return
            }
            moveIAmHere(position: currentPosition, heading: iAmHereHeading, over: 1)

            switch state {
            case .start, .showStoreInfo(_):
                if camera == .follow {
                    mapView.frame(
                        currentPosition,
                        padding: CAMERA_PADDING,
                        heading: iAmHereHeading,
                        tilt: PERSPECTIVE_TILT,
                        over: 1
                    )
                }
                break
            case .pathSelect(let path):
                guard let destination = self.destinationLocation else {
                         return
                }
                let directions = currentPosition.getDirections(to: destination, accessible: accessible)
                updatePath(newDirections: directions)
                if camera == .follow {
                    let angleRads = currentPosition.vector2.angle(to: (path.to.navigatableCoordinates.first?.vector2)!)
                    mapView.frame(
                        currentPosition,
                        padding: CAMERA_PADDING,
                        heading: angleRads,
                        tilt: PERSPECTIVE_TILT,
                        over: 1.0)
                }
                break
            case .navigation(var navigation):
                guard let destination = self.destinationLocation else {
                         return
                }
                navigation.updatePositionOnPath(from: currentPosition, to: destination, accessible: self.accessible)
                state = .navigation(navigation)
                updatePath(newDirections: navigation.directions)
                if let destinationCoordinates = navigation.directions.path.last {
                    let distance = currentPosition.meters(from: destinationCoordinates)
                    if distance < DISTANCE_FROM_DESTINATION_TO_ARRIVE {
                        if arrivalView == nil {
                            arrivalView = ArrivalNotificationView.initFromNib()
                        }
                        self.TopNavigationNotificationView.childView = arrivalView
                        self.TopNavigationNotificationView.isHidden = false

                        if directionsView != nil {
                            directionsView!.arrivedAtDestination = true
                        }
                    }
                    addAllOverlaysOnMap(from: currentPosition, to: navigation.to)
                    if(camera != .free){
                        updateNavigationView(navigation: navigation)
                    }
                }
                break
            }
        }
    }

    func updateLocationDidFailWithError(error: Error) {
        // Handle errors here
        if CLLocationManager.authorizationStatus() == .denied {
            if self.cylinder != nil,
                self.arrow != nil {
                mapView.remove(cylinder!)
                mapView.remove(arrow!)
                self.cylinder = nil
                self.arrow = nil
            }
            isUsingUserLocation = false
            iAmHereCoordinate = nil
            self.setUpPrompt()
            changeState(next: .start)
        }
    }
}

extension MapViewController: MapViewDelegate {

    // Highlights selected polygon
    private func highlight(polygon: Polygon, over: Double = 0.6) {
        self.mapView.setColor(of: polygon, to: Colors.azure, over: over)
    }

    // Utility function to handle highlighting locations with multiple polygons
    private func highlight(location: Location, over: Double = 0.6) {
        for polygon in location.polygons {
            highlight(polygon: polygon, over: over)
        }
    }
    // Utility function that handles highlighting all types of navigatables and finds their polygon(s)
    private func highlight(navigatable: Navigatable, over: Double = 0.6) {
        switch navigatable {
        case let polygon as Polygon:
            highlight(polygon: polygon, over: over)
        case let location as Location:
            highlight(location: location, over: over)
        default:
            return
        }
    }

    // Unhighlights selected polygon
    private func unhighlight(polygon: Polygon) {
        mapView.setColor(of: polygon, to: polygon.defaultColor, over: 0.6)
    }

    // Utility function to handle unhighlighting locations with multiple polygons
    private func unhighlight(location: Location) {
        for polygon in location.polygons {
            unhighlight(polygon: polygon)
        }
    }

    // Utility function that handles unhighlighting all types of navigatables and finds their polygon(s)
    private func unhighlight(navigatable: Navigatable) {
        switch navigatable {
        case let polygon as Polygon:
            unhighlight(polygon: polygon)
        case let location as Location:
            unhighlight(location: location)
        default:
            return
        }
    }

    // Triggers whenever the user touches the mapView to scroll/zoom/rotate
    func manipulatedCamera() {
        camera = .free
    }

    // Handles all image overlay taps within the mapView (only required during path preview or wayfinding)
    func tapped(_ mapView: MapView, element: Element) -> Bool {
        guard let currentPath = self.path else { return false }
        switch state {
        case .pathSelect(let path):
            camera = .free
            if let overlay = element as? ImageOverlay {
                self.map = self.overlaysOnMap[overlay.coordinate!]?.sibling!.getMap()
                highlight(navigatable: path.to)
                if let startingLocation = self.startingLocation {
                    highlight(navigatable: startingLocation)
                }
                self.closeLevelSelector()
                mapView.frame(currentPath,
                              padding: CAMERA_PADDING,
                              heading: mapView.cameraHeading,
                              tilt: mapView.cameraTilt,
                              over: 1.0)
                return true
            }
            return false
        case .navigation(let nav):
            camera = .free
            if let overlay = element as? ImageOverlay {
                
                self.map = self.overlaysOnMap[overlay.coordinate!]?.sibling!.getMap()
                highlight(navigatable: nav.to)
                if let startingLocation = self.startingLocation {
                    highlight(navigatable: startingLocation)
                }
                self.closeLevelSelector()
                mapView.frame(currentPath,
                              padding: CAMERA_PADDING,
                              heading: mapView.cameraHeading,
                              tilt: mapView.cameraTilt,
                              over: 1.0)
                return true
            }
            return false
        default:
            return false
        }
    }

     // Checks if polygon is the same as or shares the same location as the given Navigatable
     func isPolygonSameAsNavigatable(navigatable: Navigatable?, polygon: Polygon) -> Bool {
        if let navigatableAsLocation = navigatable as? Venue.Tenant {
            for i in polygon.locations {
                if navigatableAsLocation == i {
                    return true
                }
            }
         }
         else if let navigatableAsPolygon = navigatable as? Polygon {
            if navigatableAsPolygon == polygon {
                return true
            }
        }
         else if navigatable == nil {
            return false
        }
        return false
     }

    // Handles all polygon taps within the mapView
    func tapped(_ mapView: MapView, polygon: Polygon) -> Bool {
        let polygonIsStartingLocation = isPolygonSameAsNavigatable(navigatable: startingLocation, polygon: polygon)
        switch state {
        case .start:
            if polygon.locations.first != nil {
                if !isUsingUserLocation {
                    if startingLocation == nil {
                        startingLocation = polygon
                        self.camera = .free
                        self.highlight(polygon: polygon)
                        self.mapView.frame(
                            polygon,
                            padding: CAMERA_PADDING,
                            heading: self.mapView.cameraHeading,
                            tilt: PERSPECTIVE_TILT,
                            over: 0.6
                        )
                        self.searchView?.searchBar.placeholder = "enter your destination"
                        promptChooseDestination()
                    } else {
                        if polygonIsStartingLocation == false {
                            checkDestinationLocation(newDestination: polygon)
                            hidePrompt()
                            changeState(next: .showStoreInfo(polygon))
                        }
                    }
                } else {
                    self.destinationLocation = polygon
                    changeState(next: .showStoreInfo(polygon))
                }
                self.backButton.isHidden = false
                return true
            }
            return false
        case .showStoreInfo:
            if polygon.locations.first != nil {
                if !isUsingUserLocation {
                    if startingLocation == nil {
                        startingLocation = polygon
                    } else {
                        if polygonIsStartingLocation == false {
                            checkDestinationLocation(newDestination: polygon)
                            hidePrompt()
                        }
                    }
                } else {
                    checkDestinationLocation(newDestination: polygon)
                }
                changeState(next: .showStoreInfo(polygon))
                return true
            }
            return false
        case .pathSelect(_):
            if polygon.locations.first != nil {
                if polygonIsStartingLocation == false {
                    checkDestinationLocation(newDestination: polygon)
                    changeState(next: .showStoreInfo(polygon))
                    return true
                }
            }
            return false
        case .navigation(_):
            if polygon.locations.first != nil {
                let alert = UIAlertController(title: "New Location Selected",
                                              message: "\nWould you like to cancel wayfinding and view the new location?",
                                              preferredStyle: UIAlertController.Style.alert
                                             )
                alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: {(alert: UIAlertAction!) in
                    if polygonIsStartingLocation == false {
                        self.checkDestinationLocation(newDestination: polygon)
                        self.changeState(next: .showStoreInfo(polygon))
                    }
                }))
                    
                alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default , handler: nil))
                self.present(alert, animated: true, completion: nil)
                return true
            }
            return false
        }
    }
    
    private func checkDestinationLocation(newDestination: Navigatable) {
        if self.destinationLocation != nil {
            self.unhighlight(navigatable: self.destinationLocation!)
        }
        
        self.destinationLocation = newDestination
        if self.destinationLocation != nil {
            self.highlight(navigatable: self.destinationLocation!)
            self.displayDestinationIcon(navigatable: self.destinationLocation!)
        }
    }

    // Adds an overlay image to the polygon when it gets selected
    private func displayDestinationIcon (navigatable: Navigatable) {
        let destinationIcon = UIImage(named: "destinationIcon")
        if let destinationIconImage = destinationIcon {
            let overlaySize = CGSize(width: destinationIconImage.size.width, height: destinationIconImage.size.height)
            if let navCoords = navigatable.navigatableCoordinates.first {
                if self.destinationOverlay != nil {
                    self.mapView.remove(self.destinationOverlay!)
                }
                self.destinationOverlay = ImageOverlay.init(position: navCoords, image: destinationIconImage, size: overlaySize, anchorPoint: .bottom)
                if self.destinationOverlay != nil {
                    self.mapView.add(self.destinationOverlay!)
                }
            }
        }
    }
    private func addIconToDictionary(coordinates: Coordinate, iconName: String, overlay: ImageOverlay){
        //add to the dictionaries
        overlaysOnMap[coordinates] = OverlayWrapper(name: iconName, image: overlay, sibling: nil)
        //render it in the map
        self.mapView.add(overlay)
    }
    
    private func removeIcon(coordinates: Coordinate){
        // remove from the mapview
        let overlay:ImageOverlay = self.overlaysOnMap[coordinates]!.image
        self.mapView.remove(overlay)
        
        // remove from the dictionaries
        self.overlaysOnMap[coordinates] = nil
    }
}

// Generates image overlays from instructions for all floor changes
// Returns icon depending on the type of connection
extension MapViewController {
    func getFloorChangeOverlay (instruction: Directions.Instruction)->String?{
        let action = instruction.action as! Directions.Instruction.TakeConnection
        var overlayIconName:String

        if action.fromMap.floor < action.toMap.floor {
            switch instruction.atLocation?.type {
            case "elevator"?:
                overlayIconName = "ElevatorUp"
                break
            case "escalator"?:
                overlayIconName = "EscalatorUp"
                break
            case "stairs"?:
                overlayIconName = "StairsUp"
                break
            default:
                overlayIconName = "RampUp"
                break
            }
        } else {
            switch instruction.atLocation?.type {
            case "elevator"?:
                overlayIconName = "ElevatorDown"
                break
            case "escalator"?:
                overlayIconName = "EscalatorDown"
                break
            case "stairs"?:
                overlayIconName = "StairsDown"
                break
            default:
                overlayIconName = "RampDown"
                break
            }
        }
        
        //exit if the icon already exists
        if (self.overlaysOnMap[instruction.coordinate] != nil){
            return overlayIconName;
        }
        
        let overlay:ImageOverlay = configureIcon(overlayIconName: overlayIconName, connection: instruction.coordinate)
        
        renderCorrectIcons(coordinates: instruction.coordinate,
                           overlay: overlay,
                           iconName: overlayIconName)
        
        return overlayIconName
    }
    
    func getFloorChangeOverlay (connection: Coordinate, previousType: String){
        var name:String?
        
            switch previousType {
            case "ElevatorDown":
                name = "ElevatorUp"
                break
            case "EscalatorDown":
                name = "EscalatorUp"
                break
            case "StairsDown":
                name = "StairsUp"
                break
            case "RampDown":
                name = "RampUp"
                break
            case "ElevatorUp":
                name = "ElevatorDown"
                break
            case "EscalatorUp":
                name = "EscalatorDown"
                break
            case "StairsUp":
                name = "StairsDown"
                break
            case "RampUp":
                name = "RampDown"
                break
            default:
                name = nil
            }
        
        guard let overlayIconName = name else{return}
        
        //exit if the icon already exists
        if (self.overlaysOnMap[connection] != nil){
            return;
        }
        
        let overlay:ImageOverlay = configureIcon(overlayIconName: overlayIconName, connection: connection)
        
        renderCorrectIcons(coordinates: connection,
                           overlay: overlay,
                           iconName: overlayIconName)
    }
    
    private func configureIcon(overlayIconName:String, connection:Coordinate)->ImageOverlay{
        let overlayIcon = UIImage(named: overlayIconName)
        
        let circle = UIImage.circle(diameter: overlayIcon!.size.width, color: Colors.azure)
        let background = UIImage(cgImage: circle.cgImage!, scale: 1.2, orientation: circle.imageOrientation)
        let backgroundSize = CGSize(width: (background.size.width), height: background.size.width)
        let iconWidth = overlayIcon?.size.width
        let iconSize = CGSize(width: iconWidth!, height: iconWidth!)
        let overlaySize = CGSize(width: iconWidth!/2, height: iconWidth!/2)
        
        UIGraphicsBeginImageContext(backgroundSize)
        let iconOrigin = backgroundSize.width/2 - ((overlayIcon?.size.width)!/2)
        background.draw(in: CGRect(x: 0, y: 0, width: backgroundSize.width, height: backgroundSize.width))
        let iconProperties:CGRect = CGRect(x: iconOrigin, y: iconOrigin, width: iconSize.width, height: iconSize.width)
        overlayIcon!.draw(in: iconProperties)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return ImageOverlay(position: connection, image: newImage, size: overlaySize)
    }
    
    private func renderCorrectIcons(coordinates:Coordinate, overlay:ImageOverlay, iconName:String){
        if self.overlaysOnMap[coordinates] != nil{
                self.removeIcon(coordinates: coordinates)
                self.addIconToDictionary(coordinates: coordinates, iconName: iconName, overlay: overlay)
                //there are no images, simply add it
            }

            // the dictionary does not have an image entry
        else{
            self.addIconToDictionary(coordinates: coordinates, iconName: iconName, overlay: overlay)
        }
    }
}

// Utility function to create circle backgrounds for Image Overlays
extension UIImage {
    class func circle(diameter: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        let rect = CGRect(x: 4, y: 4, width: diameter-8, height: diameter-8)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)
        ctx.setStrokeColor(gray: 1.0, alpha: 1.0)
        ctx.setLineWidth(8.0)
        ctx.strokeEllipse(in: rect)
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}

extension UIView {
    func roundSpecifiedCorners(object: UIView, radius: CGFloat, corners: CACornerMask) {
        object.layer.cornerRadius = radius
        object.layer.maskedCorners = corners
    }
}
