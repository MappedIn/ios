import UIKit
import Mappedin

final class MultiFloorViewDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Multi-Floor View"
        view.backgroundColor = .systemBackground

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
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "67a6641530e940000bac3c1a"
        )

		// Load the map data.
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                print("getMapData success")

				// Display the map with multi-floor view enabled.
                let show3dMapOptions = Show3DMapOptions(
                    multiFloorView: Show3DMapOptions.MultiFloorViewOptions(
                        enabled: true,
                        floorGap: 10.0,
                        updateCameraElevationOnFloorChange: true
                    )
                )

                self.mapView.show3dMap(options: show3dMapOptions) { r2 in
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

	// Place your code to be called when the map is ready here.
	private func onMapReady() {
		print("show3dMap success - Map displayed with multi-floor view")

		// Get all floors and find the ones we need.
		mapView.mapData.getByType(MapDataType.floor) { [weak self] (result: Result<[Floor], Error>) in
			guard let self = self else { return }
			switch result {
			case .success(let floors):
				// Set the current floor to the one with elevation 9.
				if let floor9 = floors.first(where: { $0.elevation == 9.0 }) {
					self.mapView.setFloor(floorId: floor9.id) { _ in
						print("Set floor to elevation 9: \(floor9.name)")
					}
				}

				// Show the 6th floor (elevation 6) as well.
				if let floor6 = floors.first(where: { $0.elevation == 6.0 }) {
					self.mapView.updateState(
						floor: floor6,
						state: FloorUpdateState(
							geometry: FloorUpdateState.Geometry(visible: true)
						)
					) { _ in
						print("Made floor with elevation 6 visible: \(floor6.name)")
					}
				}
			case .failure(let error):
				print("Failed to get floors: \(error)")
			}
		}
	}
}

