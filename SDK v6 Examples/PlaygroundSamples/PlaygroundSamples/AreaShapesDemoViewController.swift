import UIKit
import Mappedin

final class AreaShapesDemoViewController: UIViewController {
    private let mapView = MapView()
    private var forkLiftArea: Area?
    private var maintenanceArea: Area?
    private var currentFloor: Floor?
    private var origin: MapObject?
    private var destination: Door?

    // UI Elements
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let activePeriodLabel = UILabel()
    private let toggleContainer = UIView()
    private let toggleLabel = UILabel()
    private let pathToggle = UISwitch()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Areas & Shapes"
        view.backgroundColor = .systemBackground

        // Setup header
        setupHeader()

        // Setup toggle
        setupToggle()

        // Setup map view
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: toggleContainer.bottomAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "667b26b38298d5000b85eeb0")
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    if case .success = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        self.onMapReady()
                    } else if case .failure = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
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

    private func setupHeader() {
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        NSLayoutConstraint.activate([
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])

        titleLabel.text = "Areas & Shapes"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleLabel)

        descriptionLabel.text = "Demonstrates drawing shapes from areas, labeling them, and routing with zone avoidance."
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(descriptionLabel)

        activePeriodLabel.text = getActivePeriod()
        activePeriodLabel.font = .systemFont(ofSize: 12)
        activePeriodLabel.textColor = .systemGray2
        activePeriodLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(activePeriodLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),

            descriptionLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            activePeriodLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            activePeriodLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            activePeriodLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            activePeriodLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
        ])
    }

    private func setupToggle() {
        toggleContainer.translatesAutoresizingMaskIntoConstraints = false
        toggleContainer.backgroundColor = .systemGray6
        view.addSubview(toggleContainer)

        NSLayoutConstraint.activate([
            toggleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toggleContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            toggleContainer.heightAnchor.constraint(equalToConstant: 56),
        ])

        toggleLabel.text = "Human Safe Path"
        toggleLabel.font = .systemFont(ofSize: 14)
        toggleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleContainer.addSubview(toggleLabel)

        pathToggle.isOn = false
        pathToggle.addAction(UIAction { [weak self] _ in
            self?.toggleChanged()
        }, for: .valueChanged)
        pathToggle.translatesAutoresizingMaskIntoConstraints = false
        toggleContainer.addSubview(pathToggle)

        NSLayoutConstraint.activate([
            toggleLabel.leadingAnchor.constraint(equalTo: toggleContainer.leadingAnchor, constant: 16),
            toggleLabel.centerYAnchor.constraint(equalTo: toggleContainer.centerYAnchor),

            pathToggle.trailingAnchor.constraint(equalTo: toggleContainer.trailingAnchor, constant: -16),
            pathToggle.centerYAnchor.constraint(equalTo: toggleContainer.centerYAnchor),
        ])
    }

    private func toggleChanged() {
        drawPath(avoidZone: pathToggle.isOn) // when ON, avoid zone for human safety
    }

    private func onMapReady() {
        // Set camera position
        let cameraTarget = CameraTarget(
            bearing: 0.3680689187522478,
            center: Coordinate(latitude: 43.49109852349488, longitude: -79.61573677603003),
            pitch: 49.274370381250826,
            zoomLevel: 18.283635634745174
        )

        mapView.camera.set(target: cameraTarget) { [weak self] _ in
            guard let self = self else { return }

            // Animate camera to closer view
            let animationTarget = CameraTarget(
                bearing: 0.3680689187522478,
                center: Coordinate(latitude: 43.49109852349488, longitude: -79.61573677603003),
                pitch: 49.274370381250826,
                zoomLevel: 19.999995755401297
            )

            self.mapView.camera.animateTo(
                target: animationTarget,
                options: CameraAnimationOptions(duration: 2000, easing: .easeInOut)
            ) { _ in
                // Camera animation complete, now load areas and create shapes
                self.loadAreasAndShapes()
            }
        }
    }

    private func loadAreasAndShapes() {
        // Get current floor for zone avoidance
        mapView.currentFloor { [weak self] result in
            guard let self = self else { return }
            if case .success(let floor) = result {
                self.currentFloor = floor

                // Get all areas
                self.mapView.mapData.getByType(.area) { [weak self] (result: Result<[Area], Error>) in
                    guard let self = self else { return }
                    if case .success(let areas) = result {
                        // Find the Forklift Area
                        self.forkLiftArea = areas.first { $0.name == "Forklift Area" }
                        if let area = self.forkLiftArea {
                            self.createShapeFromArea(
                                area: area,
                                labelText: "Maintenance Area",
                                color: "red",
                                opacity: 0.7,
                                altitude: 0.2,
                                height: 0.1
                            )
                        }

                        // Find the Maintenance Area
                        self.maintenanceArea = areas.first { $0.name == "Maintenance Area" }
                        if let area = self.maintenanceArea {
                            self.createShapeFromArea(
                                area: area,
                                labelText: "Forklift Area",
                                color: "orange",
                                opacity: 0.7,
                                altitude: 0.2,
                                height: 1.0
                            )
                        }

                        // Get origin and destination for paths
                        self.setupPathEndpoints()
                    }
                }
            }
        }
    }

    private func createShapeFromArea(area: Area, labelText: String, color: String, opacity: Double, altitude: Double, height: Double) {
        // Get the GeoJSON Feature from the area
        guard let feature = area.geoJSON else { return }

        // Create a FeatureCollection containing the single Feature
        let featureCollection = FeatureCollection(features: [feature])

        // Draw the shape using the typed API
        mapView.shapes.add(
            geometry: featureCollection,
            style: PaintStyle(color: color, altitude: altitude, height: height, opacity: opacity)
        ) { _ in }

        // Label the area
        mapView.labels.add(target: area, text: labelText) { _ in }
    }

    private func setupPathEndpoints() {
        // Get objects for origin
        mapView.mapData.getByType(.mapObject) { [weak self] (objResult: Result<[MapObject], Error>) in
            guard let self = self else { return }
            if case .success(let objects) = objResult {
                self.origin = objects.first { $0.name == "I3" }

                // Get doors for destination
                self.mapView.mapData.getByType(.door) { [weak self] (doorResult: Result<[Door], Error>) in
                    guard let self = self else { return }
                    if case .success(let doors) = doorResult {
                        self.destination = doors.first { $0.name == "Outbound Shipments 1" }

                        // Draw initial path (forklift path, not avoiding zone)
                        if self.origin != nil && self.destination != nil {
                            self.drawPath(avoidZone: false)
                        }
                    }
                }
            }
        }
    }

    private func drawPath(avoidZone: Bool) {
        // Remove existing paths
        mapView.paths.removeAll()

        guard let origin = origin,
              let destination = destination,
              let maintenanceArea = maintenanceArea else {
            return
        }

        // Create NavigationTargets
        let from = NavigationTarget.mapObject(origin)
        let to = NavigationTarget.door(destination)

        // Create zone for avoidance if needed
        var options: GetDirectionsOptions?
        if avoidZone, let feature = maintenanceArea.geoJSON, let currentFloor = currentFloor {
            let zone = DirectionZone(
                cost: Double.greatestFiniteMagnitude,
                floor: currentFloor,
                geometry: feature
            )
            options = GetDirectionsOptions(zones: [zone])
        }

        // Get directions
        mapView.mapData.getDirections(from: from, to: to, options: options) { [weak self] result in
            guard let self = self else { return }
            if case .success(let directions) = result, let directions = directions {
                // Draw the path
                let pathColor = avoidZone ? "cornflowerblue" : "green"
                self.mapView.paths.add(
                    coordinates: directions.coordinates,
                    options: AddPathOptions(color: pathColor)
                ) { _ in }
            }
        }
    }

    private func getActivePeriod() -> String {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 14, to: start) ?? start

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}
