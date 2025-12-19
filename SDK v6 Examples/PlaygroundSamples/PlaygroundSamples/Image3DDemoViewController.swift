import UIKit
import Mappedin

final class Image3DDemoViewController: UIViewController {
    private let mapView = MapView()
    private var arenaFloor: Space?
    private let pixelsToMeters = 0.0617
    private let imageSegmentedControl = UISegmentedControl(items: ["Hockey", "Basketball", "Concert"])
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Image3D"
        view.backgroundColor = .systemBackground

        // Setup segmented control
        imageSegmentedControl.selectedSegmentIndex = 0
        imageSegmentedControl.addAction(UIAction { [weak self] _ in
            self?.imageSelectionChanged()
        }, for: .valueChanged)
        imageSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageSegmentedControl)

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            imageSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            imageSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: imageSegmentedControl.bottomAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "672a6f4f3a45ba000b893e1c")
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
        // Add labels to all named spaces
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }
            if case .success(let spaces) = result {
                spaces.filter { !$0.name.isEmpty }.forEach { space in
                    self.mapView.labels.add(target: space, text: space.name, options: AddLabelOptions(interactive: true)) { _ in }
                }

                // Find the Arena Floor space
                self.arenaFloor = spaces.first { $0.name == "Arena Floor" }

                // Add the default hockey image to the arena floor
                if let floor = self.arenaFloor {
                    let imageName = self.getImageName(for: 0)
                    let opts = AddImageOptions(
                        height: 448 * self.pixelsToMeters,
                        width: 1014 * self.pixelsToMeters,
                        flipImageToFaceCamera: false,
                        rotation: 239.0,
                        verticalOffset: 1.0
                    )
                    self.mapView.image3D.add(target: floor, url: imageName, options: opts) { _ in }
                }
            }
        }
    }

    private func imageSelectionChanged() {
        guard let floor = arenaFloor else { return }

        mapView.image3D.removeAll()

        let imageName = getImageName(for: imageSegmentedControl.selectedSegmentIndex)
        let opts = AddImageOptions(
            height: 448 * pixelsToMeters,
            width: 1014 * pixelsToMeters,
            flipImageToFaceCamera: false,
            rotation: 239.0,
            verticalOffset: 1.0
        )
        mapView.image3D.add(target: floor, url: imageName, options: opts) { _ in }
    }

    private func getImageName(for index: Int) -> String {
        let imageName: String
        switch index {
        case 0: imageName = "arena_hockey"
        case 1: imageName = "arena_basketball"
        case 2: imageName = "arena_concert"
        default: imageName = "arena_hockey"
        }

        // Use mappedin-asset:// URL scheme.
         if let assetUrl = Bundle.main.mappedinAssetURL(forResource: imageName, withExtension: "png") {
             return assetUrl
         }

        // Fallback to just the name if image not found.
        return imageName
    }
}


