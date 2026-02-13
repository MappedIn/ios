import UIKit
import Mappedin

final class QueryDemoViewController: UIViewController {
    private let mapView = MapView()
    private var highlightedSpace: Space?
    private var originalColor: String?
    private let instructionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let queryModeControl = UISegmentedControl(items: ["Nearest", "At"])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Query"
        view.backgroundColor = .systemBackground

        // Setup query mode toggle
        queryModeControl.selectedSegmentIndex = 0
        queryModeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(queryModeControl)

        // Setup instruction label
        instructionLabel.text = "Click on the map to query. Use the toggle to switch between nearest and at."
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.textColor = .label
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            queryModeControl.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            queryModeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            queryModeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: queryModeControl.bottomAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "660c0bb9ae0596d87766f2d9")
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

    private func onMapReady() {
        // Handle click events
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self = self, let clickPayload = clickPayload else { return }

            let coordinate = clickPayload.coordinate

            print("Query: Click coordinate: lat=\(coordinate.latitude), lon=\(coordinate.longitude), floor=\(coordinate.floorId ?? "nil")")

            // Reset previously highlighted space to its original color
            if let space = self.highlightedSpace, let color = self.originalColor {
                self.mapView.updateState(space: space, state: GeometryUpdateState(color: color))
            }

            let useAtQuery = self.queryModeControl.selectedSegmentIndex == 1

            if useAtQuery {
                // Query.at: find all geometry at the clicked coordinate
                print("Query: Calling at with coordinate")
                self.mapView.mapData.query.at(coordinate: coordinate) { result in
                    print("Query: at callback received")
                    switch result {
                    case .success(let atResults):
                        print("Query: atResults count: \(atResults?.count ?? 0)")
                        let firstSpace = atResults?.first { result in
                            if case .space = result { return true }
                            return false
                        }
                        if case .space(let space) = firstSpace {
                            print("Query: Space at point: \(space.name) (\(atResults?.count ?? 0) geometry at point)")

                            self.mapView.getState(space: space) { stateResult in
                                if case .success(let state) = stateResult {
                                    self.originalColor = state?.color
                                    self.mapView.updateState(space: space, state: GeometryUpdateState(color: "#FF6B35"))
                                    self.highlightedSpace = space
                                    DispatchQueue.main.async {
                                        self.instructionLabel.text = "Highlighted: \(space.name) (\(atResults?.count ?? 0) geometry at point)"
                                    }
                                }
                            }
                        } else {
                            print("Query: No space at click location")
                            DispatchQueue.main.async {
                                self.instructionLabel.text = "No space at click. \(atResults?.count ?? 0) geometry found."
                            }
                        }
                    case .failure(let error):
                        print("Query: at failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.instructionLabel.text = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                // Query.nearest: find the nearest space to the clicked coordinate
                print("Query: Calling nearest with coordinate")
                self.mapView.mapData.query.nearest(origin: coordinate, include: [.space]) { result in
                    print("Query: nearest callback received")
                    switch result {
                    case .success(let queryResults):
                        print("Query: queryResults count: \(queryResults?.count ?? 0)")
                        guard let nearestResult = queryResults?.first else {
                            DispatchQueue.main.async {
                                self.instructionLabel.text = "No space found near click location."
                            }
                            return
                        }

                        if case .space(let space) = nearestResult.feature {
                            print("Query: Nearest space: \(space.name) at \(nearestResult.distance)m")

                            self.mapView.getState(space: space) { stateResult in
                                if case .success(let state) = stateResult {
                                    self.originalColor = state?.color
                                    self.mapView.updateState(space: space, state: GeometryUpdateState(color: "#FF6B35"))
                                    self.highlightedSpace = space
                                    DispatchQueue.main.async {
                                        self.instructionLabel.text = "Highlighted: \(space.name) (\(String(format: "%.1f", nearestResult.distance))m away)"
                                    }
                                }
                            }
                        } else {
                            print("Query: No space feature found")
                            DispatchQueue.main.async {
                                self.instructionLabel.text = "No space found near click location."
                            }
                        }
                    case .failure(let error):
                        print("Query: nearest failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.instructionLabel.text = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}

