import UIKit
import Mappedin

final class MarkersDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Markers are added to show annotations on the map. Click a Marker to remove it."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0x6B/255.0, green: 0x72/255.0, blue: 0x80/255.0, alpha: 1.0)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Markers"
        view.backgroundColor = .systemBackground

        // Add description label
        view.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

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
            container.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "67a6641530e940000bac3c1a")
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
        mapView.mapData.getByType(.annotation) { [weak self] (result: Result<[Annotation], Error>) in
            guard let self = self else { return }
            if case .success(let annotations) = result {
                let opts = AddMarkerOptions(
					interactive: .True,
                    placement: .single(.center),
                    rank: .tier(.high)
                )

                // Add markers for all annotations that have icons
                annotations.forEach { annotation in
                    let iconUrl = annotation.icon?.url ?? ""
                    let markerHtml = """
                    <div class='mappedin-annotation-marker'>
                        <div style='width: 30px; height: 30px'>
                        <img src='\(iconUrl)' alt='\(annotation.name)' width='30' height='30' />
                        </div>
                    </div>
                    """
                    self.mapView.markers.add(target: annotation, html: markerHtml, options: opts) { _ in }
                }

                // Remove markers that are clicked on
                self.mapView.on(Events.click) { [weak self] clickPayload in
                    guard let self = self,
                          let clickedMarker = clickPayload?.markers?.first else { return }
                    self.mapView.markers.remove(marker: clickedMarker) { _ in }
                }
            }
        }
    }
}


