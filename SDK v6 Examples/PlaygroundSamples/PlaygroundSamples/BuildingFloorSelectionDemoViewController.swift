import UIKit
import Mappedin

final class BuildingFloorSelectionDemoViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    private let mapView = MapView()
    private let buildingPicker = UIPickerView()
    private let floorPicker = UIPickerView()
    private let buildingLabel = UILabel()
    private let floorLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var floorStacks: [FloorStack] = []
    private var buildings: [FloorStack] = []
    private var allFloors: [Floor] = []
    private var currentFloors: [Floor] = []
    private var isUpdatingFromEvent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Building & Floor Selection"
        view.backgroundColor = .systemBackground

        setupUI()
        loadMap()
    }

    private func setupUI() {
        // Building label
        buildingLabel.text = "Building:"
        buildingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        buildingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buildingLabel)

        // Building picker
        buildingPicker.delegate = self
        buildingPicker.dataSource = self
        buildingPicker.translatesAutoresizingMaskIntoConstraints = false
        buildingPicker.tag = 0 // Tag to identify in picker delegate
        view.addSubview(buildingPicker)

        // Floor label
        floorLabel.text = "Floor:"
        floorLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        floorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floorLabel)

        // Floor picker
        floorPicker.delegate = self
        floorPicker.dataSource = self
        floorPicker.translatesAutoresizingMaskIntoConstraints = false
        floorPicker.tag = 1 // Tag to identify in picker delegate
        view.addSubview(floorPicker)

        // Map view
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            buildingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            buildingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buildingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buildingPicker.topAnchor.constraint(equalTo: buildingLabel.bottomAnchor, constant: 4),
            buildingPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buildingPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buildingPicker.heightAnchor.constraint(equalToConstant: 100),

            floorLabel.topAnchor.constraint(equalTo: buildingPicker.bottomAnchor, constant: 8),
            floorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            floorPicker.topAnchor.constraint(equalTo: floorLabel.bottomAnchor, constant: 4),
            floorPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floorPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floorPicker.heightAnchor.constraint(equalToConstant: 100),

            container.topAnchor.constraint(equalTo: floorPicker.bottomAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func loadMap() {
        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "682e13a2703478000b567b66"
        )
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    if case .success = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        self.onMapReady()
                    } else if case .failure(let error) = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap error: \(error)")
                    }
                }
            } else if case .failure(let error) = r {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                print("getMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        // Get all floor stacks
        mapView.mapData.getByType(.floorStack) { [weak self] (result: Result<[FloorStack], Error>) in
            guard let self = self else { return }
            if case .success(let stacks) = result {
                self.floorStacks = stacks.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

                // Filter to get only buildings (type == .building)
                self.buildings = self.floorStacks.filter { $0.type == .building }

                // If no buildings found with type filter, use all floor stacks that have geoJSON
                if self.buildings.isEmpty {
                    self.buildings = self.floorStacks.filter { $0.geoJSON != nil }
                }

                // Get all floors
                self.mapView.mapData.getByType(.floor) { [weak self] (floorsResult: Result<[Floor], Error>) in
                    guard let self = self else { return }
                    if case .success(let floors) = floorsResult {
                        self.allFloors = floors
                        self.populateFloorStacks()
                        self.setupListeners()
                    }
                }
            }
        }
    }

    // Populate the building selector with the available floor stacks.
    private func populateFloorStacks() {
        buildingPicker.reloadAllComponents()

        // Set the initial building to the current building.
        mapView.currentFloorStack { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentFloorStack) = result, let stack = currentFloorStack {
                if let index = self.floorStacks.firstIndex(where: { $0.id == stack.id }) {
                    self.buildingPicker.selectRow(index, inComponent: 0, animated: false)
                    self.populateFloors(floorStackId: stack.id)
                }
            }
        }
    }

    // Populate the floor selector with the floors in the selected floor stack.
    private func populateFloors(floorStackId: String) {
        guard let floorStack = floorStacks.first(where: { $0.id == floorStackId }) else { return }

        // Get Floor objects for all floor IDs in this floor stack
        currentFloors = floorStack.floors
            .compactMap { floorId in allFloors.first(where: { $0.id == floorId }) }
            .sorted { $0.elevation > $1.elevation }

        floorPicker.reloadAllComponents()

        // Set the initial floor to the current floor.
        mapView.currentFloor { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentFloor) = result, let floor = currentFloor {
                if let index = self.currentFloors.firstIndex(where: { $0.id == floor.id }) {
                    self.floorPicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
        }
    }

    private func setupListeners() {
        // Act on the click event to check if the coordinate is within any building.
        mapView.on(Events.click) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            let coordinate = payload.coordinate
            var matchingBuildings: [String] = []

			// This demonstrates how to detect if a coordinate is within a building.
			// For click events, this can be detected by checking the ClickEvent.floors.
			// Checking the coordinate is for demonstration purposes and useful for non click events.
            for building in self.buildings {
                if self.isCoordinateWithinFeature(coordinate: coordinate, feature: building.geoJSON) {
                    matchingBuildings.append(building.name)
                }
            }

            DispatchQueue.main.async {
                let message: String
                if !matchingBuildings.isEmpty {
                    message = "Coordinate is within building: \(matchingBuildings.joined(separator: ", "))"
                } else {
                    message = "Coordinate is not within any building"
                }
                self.showToast(message: message)
            }
        }

        // Act on the floor-change event to update the floor selector.
        mapView.on(Events.floorChange) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            print("Floor changed to: \(payload.floor.name) in building: \(payload.floor.floorStack?.name ?? "unknown")")

            self.isUpdatingFromEvent = true
            // Find the floor in our current floor selector
            if let index = self.currentFloors.firstIndex(where: { $0.id == payload.floor.id }) {
                self.floorPicker.selectRow(index, inComponent: 0, animated: false)
            }
            self.isUpdatingFromEvent = false
        }
    }

    // UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            // Building picker
            return floorStacks.count
        } else {
            // Floor picker
            return currentFloors.count
        }
    }

    // UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            // Building picker
            return row < floorStacks.count ? floorStacks[row].name : nil
        } else {
            // Floor picker
            return row < currentFloors.count ? currentFloors[row].name : nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if isUpdatingFromEvent { return }

        if pickerView.tag == 0 {
            // Building picker
            if row < floorStacks.count {
                let selectedFloorStack = floorStacks[row]
                mapView.setFloorStack(floorStackId: selectedFloorStack.id) { [weak self] _ in
                    guard let self = self else { return }
                    self.populateFloors(floorStackId: selectedFloorStack.id)
                    // Focus the camera on the current floor.
                    self.mapView.currentFloor { [weak self] result in
                        guard let self = self else { return }
                        if case .success(let currentFloor) = result, let floor = currentFloor {
                            self.mapView.camera.focusOn(floor: floor) { _ in }
                        }
                    }
                }
            }
        } else {
            // Floor picker
            if row < currentFloors.count {
                let selectedFloor = currentFloors[row]
                mapView.setFloor(floorId: selectedFloor.id) { [weak self] _ in
                    guard let self = self else { return }
                    // Focus the camera on the selected floor.
                    self.mapView.camera.focusOn(floor: selectedFloor) { _ in }
                }
            }
        }
    }

    /// Check if a coordinate is within a GeoJSON Feature.
    /// This implements point-in-polygon checking similar to @turf/boolean-contains.
    private func isCoordinateWithinFeature(coordinate: Coordinate, feature: Feature?) -> Bool {
        guard let geometry = feature?.geometry else { return false }
        let point = [coordinate.longitude, coordinate.latitude]

        switch geometry {
        case .polygon(let coordinates):
            return isPointInPolygon(point: point, polygon: coordinates)
        case .multiPolygon(let coordinates):
            return coordinates.contains { polygon in
                isPointInPolygon(point: point, polygon: polygon)
            }
        default:
            return false
        }
    }

    /// Check if a point is inside a polygon using the ray-casting algorithm.
    /// The polygon is represented as a list of linear rings (first is outer, rest are holes).
    private func isPointInPolygon(point: [Double], polygon: [[[Double]]]) -> Bool {
        guard !polygon.isEmpty else { return false }

        // Check if point is inside the outer ring
        let outerRing = polygon[0]
        guard isPointInRing(point: point, ring: outerRing) else {
            return false
        }

        // Check if point is inside any hole (if so, it's not in the polygon)
        for i in 1..<polygon.count {
            if isPointInRing(point: point, ring: polygon[i]) {
                return false
            }
        }

        return true
    }

    /// Check if a point is inside a linear ring using the ray-casting algorithm.
    /// This counts how many times a ray from the point crosses the polygon boundary.
    private func isPointInRing(point: [Double], ring: [[Double]]) -> Bool {
        guard ring.count >= 4 else { return false } // A valid ring needs at least 4 points (3 + closing point)

        let x = point[0]
        let y = point[1]
        var inside = false

        var j = ring.count - 1
        for i in 0..<ring.count {
            let xi = ring[i][0]
            let yi = ring[i][1]
            let xj = ring[j][0]
            let yj = ring[j][1]

            let intersect = ((yi > y) != (yj > y)) &&
                (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

            if intersect {
                inside = !inside
            }
            j = i
        }

        return inside
    }

    /// Shows a toast-like message at the bottom of the screen.
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0

        let maxWidth = view.frame.size.width - 40
        let expectedSize = toastLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let labelWidth = min(expectedSize.width + 20, maxWidth)
        let labelHeight = expectedSize.height + 16

        toastLabel.frame = CGRect(
            x: (view.frame.size.width - labelWidth) / 2,
            y: view.frame.size.height - 150,
            width: labelWidth,
            height: labelHeight
        )

        view.addSubview(toastLabel)

        UIView.animate(withDuration: 2.0, delay: 1.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}

