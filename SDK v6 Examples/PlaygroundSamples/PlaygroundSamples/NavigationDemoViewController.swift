import UIKit
import Mappedin

final class NavigationDemoViewController: UIViewController {
    private let mapView = MapView()
	private var currentDirections: Directions?
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation"
        view.backgroundColor = .systemBackground

		// Create heading
		let heading = UILabel()
		heading.text = "Choose Marker Option"
		heading.font = UIFont.boldSystemFont(ofSize: 16)
		heading.translatesAutoresizingMaskIntoConstraints = false

		// Create button controls
		let buttonStack = UIStackView()
		buttonStack.axis = .horizontal
		buttonStack.distribution = .fillEqually
		buttonStack.spacing = 8
		buttonStack.translatesAutoresizingMaskIntoConstraints = false

		let defaultButton = UIButton(type: .system)
		defaultButton.setTitle("Default", for: .normal)
		defaultButton.addTarget(self, action: #selector(defaultMode), for: .touchUpInside)

		let noMarkersButton = UIButton(type: .system)
		noMarkersButton.setTitle("No Start / End", for: .normal)
		noMarkersButton.addTarget(self, action: #selector(noMarkersMode), for: .touchUpInside)

		let pirateButton = UIButton(type: .system)
		pirateButton.setTitle("Custom", for: .normal)
		pirateButton.addTarget(self, action: #selector(pirateMode), for: .touchUpInside)

		buttonStack.addArrangedSubview(defaultButton)
		buttonStack.addArrangedSubview(noMarkersButton)
		buttonStack.addArrangedSubview(pirateButton)

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heading)
		view.addSubview(buttonStack)
		view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
			heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
			heading.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			heading.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

			buttonStack.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 4),
			buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			buttonStack.heightAnchor.constraint(equalToConstant: 44),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "64ef49e662fd90fe020bee61")
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
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }
            if case .success(let spaces) = result, spaces.count >= 2 {
				let origin = spaces.first(where: {$0.name == "Oak Meeting Room"})
                let destination = spaces.first(where: { $0.name == "Office 211 💼" })
				if let origin = origin, let destination = destination {
					self.mapView.mapData.getDirections(
						from: .space(origin),
						to: .space(destination)
					) { r in
						if case .success(let directions?) = r {
							self.currentDirections = directions
							self.mapView.camera.focusOn(targets: directions.coordinates.map { .coordinate($0) })
							// Draw with default mode initially
							self.drawWithMode(1)
						}
					}
				}
            }
        }
    }

	@objc private func defaultMode() {
		drawWithMode(1)
	}

	@objc private func noMarkersMode() {
		drawWithMode(2)
	}

	@objc private func pirateMode() {
		drawWithMode(3)
	}

	private func drawWithMode(_ mode: Int) {
		guard let directions = currentDirections else { return }

		// Clear existing navigation
		mapView.navigation.clear()

		let pathOptions = AddPathOptions(animateDrawing: true, color: "#4b90e2", displayArrowsOnPath: true)

		let navOptions: NavigationOptions
		switch mode {
		case 1:
			// Mode 1: Default markers (don't specify createMarkers)
			navOptions = NavigationOptions(pathOptions: pathOptions)
		case 2:
			// Mode 2: No markers for departure/destination, default for connection
			navOptions = NavigationOptions(
				createMarkers: NavigationOptions.CreateMarkers.withDefaults(
					connection: true,
					departure: false,
					destination: false
				),
				pathOptions: pathOptions
			)
		case 3:
			// Mode 3: Custom markers
			navOptions = NavigationOptions(
				createMarkers: NavigationOptions.CreateMarkers.withCustomMarkers(
					connection: NavigationOptions.CreateMarkers.CustomMarker(
						template: getPirateConnectionMarker(),
						options: AddMarkerOptions(interactive: .True, rank: .tier(.alwaysVisible))
					),
					departure: NavigationOptions.CreateMarkers.CustomMarker(
						template: getPirateDepartureMarker(),
						options: AddMarkerOptions(interactive: .True, rank: .tier(.alwaysVisible))
					),
					destination: NavigationOptions.CreateMarkers.CustomMarker(
						template: getPirateDestinationMarker(),
						options: AddMarkerOptions(interactive: .True, rank: .tier(.alwaysVisible))
					)
				),
				pathOptions: pathOptions
			)
		default:
			navOptions = NavigationOptions(pathOptions: pathOptions)
		}

		mapView.navigation.draw(directions: directions, options: navOptions) { _ in }
	}

	private func getPirateDepartureMarker() -> String {
		return """
		<svg width="48" height="48" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
			<!-- Pirate Ship -->
			<circle cx="24" cy="24" r="22" fill="#8B4513" opacity="0.2"/>
			<path d="M12 28 L12 22 L18 18 L30 18 L36 22 L36 28 L32 32 L16 32 Z" fill="#8B4513" stroke="#5D2E0F" stroke-width="2"/>
			<rect x="22" y="10" width="4" height="12" fill="#5D2E0F"/>
			<path d="M26 10 L36 14 L26 18" fill="#DC143C"/>
			<circle cx="24" cy="24" r="3" fill="#FFD700"/>
		</svg>
		"""
	}

	private func getPirateDestinationMarker() -> String {
		return """
		<svg width="56" height="56" viewBox="0 0 56 56" xmlns="http://www.w3.org/2000/svg">
			<!-- Background glow -->
			<circle cx="28" cy="28" r="26" fill="#FFD700" opacity="0.2"/>

			<!-- Treasure chest body -->
			<rect x="14" y="24" width="28" height="18" rx="2" fill="#8B4513" stroke="#5D2E0F" stroke-width="2"/>

			<!-- Chest lid -->
			<path d="M 14 24 Q 14 18 20 16 L 36 16 Q 42 18 42 24" fill="#6D3913" stroke="#5D2E0F" stroke-width="2"/>

			<!-- Lid highlight -->
			<path d="M 16 24 Q 16 20 20 18 L 36 18 Q 40 20 40 24" fill="#8B4513"/>

			<!-- Front band -->
			<rect x="14" y="24" width="28" height="5" fill="#5D2E0F"/>

			<!-- Center lock plate -->
			<rect x="26" y="24" width="4" height="18" fill="#5D2E0F"/>

			<!-- Lock -->
			<circle cx="28" cy="33" r="3" fill="#DAA520" stroke="#8B6914" stroke-width="1"/>
			<circle cx="28" cy="33" r="1.5" fill="#5D2E0F"/>

			<!-- Gold coins spilling out -->
			<circle cx="20" cy="30" r="2.5" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
			<circle cx="36" cy="30" r="2.5" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
			<circle cx="18" cy="36" r="2" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
			<circle cx="38" cy="36" r="2" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
			<circle cx="24" cy="38" r="2" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
			<circle cx="32" cy="38" r="2" fill="#FFD700" stroke="#DAA520" stroke-width="1"/>
		</svg>
		"""
	}

	private func getPirateConnectionMarker() -> String {
		return """
		<svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
			<!-- Compass -->
			<circle cx="20" cy="20" r="18" fill="#2C3E50" opacity="0.2"/>
			<circle cx="20" cy="20" r="14" fill="#34495E" stroke="#95A5A6" stroke-width="2"/>
			<circle cx="20" cy="20" r="10" fill="#2C3E50"/>
			<path d="M20 12 L23 20 L20 22 L17 20 Z" fill="#DC143C"/>
			<path d="M20 28 L23 20 L20 18 L17 20 Z" fill="#ECF0F1"/>
			<circle cx="20" cy="20" r="2" fill="#FFD700"/>
		</svg>
		"""
	}
}


