import UIKit
import Mappedin

final class TurnByTurnDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var currentDirections: Directions?
    private var currentPath: Path?
    private let segmentedControl = UISegmentedControl(items: ["Navigation", "Path"])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Turn by Turn"
        view.backgroundColor = .systemBackground

        // Setup segmented control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "67881b4666a208000badecc4"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self = self else { return }
            if case .success = result {
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
            }
        }
    }

    private func onMapReady() {
        // Add labels to all named spaces
        mapView.mapData.getByType(.space) { [weak self] (spacesResult: Result<[Space], Error>) in
            guard let self = self else { return }
            if case .success(let spaces) = spacesResult {
                spaces.forEach { space in
                    if !space.name.isEmpty {
                        self.mapView.labels.add(
                            target: space,
                            text: space.name,
                            options: AddLabelOptions(interactive: true)
                        ) { _ in }
                    }
                }

                // Find destination space
                let destination = spaces.first { $0.name == "Family Med Lab EN-09" }

                // Get origin object
                self.mapView.mapData.getByType(.mapObject) { [weak self] (objResult: Result<[MapObject], Error>) in
                    guard let self = self else { return }
                    if case .success(let objects) = objResult {
                        let origin = objects.first { $0.name == "Lobby" }

                        if let origin = origin, let destination = destination {
                            self.getAndDisplayDirections(origin: origin, destination: destination)
                        }
                    }
                }
            }
        }
    }

    private func getAndDisplayDirections(origin: MapObject, destination: Space) {
        mapView.mapData.getDirections(
            from: .mapObject(origin),
            to: .space(destination)
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let directions) = result, let directions = directions {
                self.currentDirections = directions

                // Focus on the first 3 steps in the journey
                let focusCoordinates = Array(directions.coordinates.prefix(3)).map { FocusTarget.coordinate($0) }

                let focusOptions = FocusOnOptions(
                    screenOffsets: InsetPadding(
                        bottom: 50,
                        left: 50,
                        right: 50,
                        top: 50
                    )
                )

                self.mapView.camera.focusOn(targets: focusCoordinates, options: focusOptions)

                // Add markers for each direction instruction
                self.addInstructionMarkers(directions: directions)

                // Draw navigation by default
                self.drawNavigation()
            }
        }
    }

    private func addInstructionMarkers(directions: Directions) {
        let instructions = directions.instructions

        for i in 0..<instructions.count {
            let instruction = instructions[i]
            let nextInstruction = i < instructions.count - 1 ? instructions[i + 1] : nil
            let isLastInstruction = i == instructions.count - 1

            let markerText: String
            if isLastInstruction {
                markerText = "You Arrived!"
            } else {
                let actionType = instruction.action.type
                let bearing = instruction.action.bearing?.rawValue ?? ""
                let distance = Int((nextInstruction?.distance ?? 0).rounded())
                markerText = "\(actionType) \(bearing) and go \(distance) meters"
            }

            let markerTemplate = """
            <div style="
                background: white;
                padding: 8px 12px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.15);
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                font-size: 12px;
                white-space: nowrap;
            ">
                <p style="margin: 0;">\(markerText)</p>
            </div>
            """

            mapView.markers.add(
                target: instruction.coordinate,
                html: markerTemplate,
                options: AddMarkerOptions(rank: .tier(.alwaysVisible))
            ) { _ in }
        }
    }

    @objc private func displayModeChanged() {
        // Clear existing path and navigation
        if let path = currentPath {
            mapView.paths.remove(path: path)
            currentPath = nil
        }
        mapView.navigation.clear()

        if segmentedControl.selectedSegmentIndex == 0 {
            // Navigation mode
            drawNavigation()
        } else {
            // Path mode
            drawPath()
        }
    }

    private func drawPath() {
        guard let directions = currentDirections else { return }

        let pathOptions = AddPathOptions(
			width: Width.value(0.5)
        )

        mapView.paths.add(coordinates: directions.coordinates, options: pathOptions) { [weak self] result in
            if case .success(let path) = result {
                self?.currentPath = path
            }
        }
    }

    private func drawNavigation() {
        guard let directions = currentDirections else { return }
        mapView.navigation.draw(directions: directions) { _ in }
    }
}

