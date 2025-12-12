import UIKit
import Mappedin

final class PathsDemoViewController: UIViewController {
    private let mapView = MapView()
    private var startSpace: Space?
    private var path: Path?
    private let instructionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Paths"
        view.backgroundColor = .systemBackground

        // Setup instruction label
        instructionLabel.text = "1. Click on a space to select it as the starting point."
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

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "65c0ff7430b94e3fabd5bb8c")
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
            }
        }
    }

    private func onMapReady() {
        // Set all spaces to be interactive initially
        mapView.mapData.getByType(.space) { (result: Result<[Space], Error>) in
            if case .success(let spaces) = result {
                print("PathsDemo: Found \(spaces.count) spaces")

                for space in spaces {
                    self.mapView.updateState(target: space, state: ["interactive": true]) { _ in }
                }

                // Handle click events
                self.mapView.on(Events.click) { [weak self] event in
            guard let self = self else { return }
            guard let clickPayload = event as? ClickPayload else { return }

            let spaces = clickPayload.spaces
            if spaces == nil || spaces?.isEmpty == true {
                // Click on non-space area when path exists - reset
                if self.path != nil {
                    self.mapView.paths.removeAll()
                    self.startSpace = nil
                    self.path = nil
                    self.setSpacesInteractive(interactive: true)
                    self.instructionLabel.text = "1. Click on a space to select it as the starting point."
                }
                return
            }

            guard let clickedSpace = spaces?.first else { return }

            if self.startSpace == nil {
                // Step 1: Select starting space
                self.startSpace = clickedSpace
                self.instructionLabel.text = "2. Click on another space to select it as the end point."
            } else if self.path == nil {
                // Step 2: Select ending space and create path
                guard let start = self.startSpace else { return }
                self.mapView.mapData.getDirections(
                    from: .space(start),
                    to: .space(clickedSpace)
                ) { result in
                    if case .success(let directions) = result, let directions = directions {
                        let opts = AddPathOptions(color: "#1871fb", width: .fixed(1.0))
                        self.mapView.paths.add(coordinates: directions.coordinates, options: opts) { pathResult in
                            if case .success(let createdPath) = pathResult {
                                self.path = createdPath
                                self.setSpacesInteractive(interactive: false)
                                self.instructionLabel.text = "3. Click anywhere to remove the path."
                            }
                        }
                    }
                }
            } else {
                // Step 3: Remove path and reset
                self.mapView.paths.removeAll()
                self.startSpace = nil
                self.path = nil
                self.setSpacesInteractive(interactive: true)
                self.instructionLabel.text = "1. Click on a space to select it as the starting point."
            }
                }
            }
        }
    }

    private func setSpacesInteractive(interactive: Bool) {
        mapView.mapData.getByType(.space) { (result: Result<[Space], Error>) in
            if case .success(let spaces) = result {
                for space in spaces {
                    self.mapView.updateState(target: space, state: ["interactive": interactive]) { _ in }
                }
            }
        }
    }
}
