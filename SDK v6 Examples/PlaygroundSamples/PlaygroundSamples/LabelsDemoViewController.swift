import UIKit
import Mappedin

final class LabelsDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let svgIcon = """
    <svg width="92" height="92" viewBox="-17 0 92 92" fill="none" xmlns="http://www.w3.org/2000/svg">
    	<g clip-path="url(#clip0)">
    	<path d="M53.99 28.0973H44.3274C41.8873 28.0973 40.7161 29.1789 40.7161 31.5387V61.1837L21.0491 30.7029C19.6827 28.5889 18.8042 28.1956 16.0714 28.0973H6.5551C4.01742 28.0973 2.84619 29.1789 2.84619 31.5387V87.8299C2.84619 90.1897 4.01742 91.2712 6.5551 91.2712H16.2178C18.7554 91.2712 19.9267 90.1897 19.9267 87.8299V58.3323L39.6912 88.6656C41.1553 90.878 41.9361 91.2712 44.669 91.2712H54.0388C56.5765 91.2712 57.7477 90.1897 57.7477 87.8299V31.5387C57.6501 29.1789 56.4789 28.0973 53.99 28.0973Z" fill="white"/>
    	<path d="M11.3863 21.7061C17.2618 21.7061 22.025 16.9078 22.025 10.9887C22.025 5.06961 17.2618 0.27124 11.3863 0.27124C5.51067 0.27124 0.747559 5.06961 0.747559 10.9887C0.747559 16.9078 5.51067 21.7061 11.3863 21.7061Z" fill="white"/>
    	</g>
    	<defs>
    	<clipPath id="clip0">
    	<rect width="57" height="91" fill="white" transform="translate(0.747559 0.27124)"/>
    	</clipPath>
    	</defs>
    	</svg>
    """

    private let colors = ["#FF610A", "#4248ff", "#891244", "#219ED4"]

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white
        title = "Labels Demo"

        // Header UI (title + description) above the map
        let headerContainer = UIStackView()
        headerContainer.axis = .vertical
        headerContainer.spacing = 6
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Labels"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Labels with custom styling are added to each space on the map with a name. Click on a label to remove it."
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.systemGray
        descriptionLabel.numberOfLines = 0

        headerContainer.addArrangedSubview(titleLabel)
        headerContainer.addArrangedSubview(descriptionLabel)

        let webview = mapView.view
        webview.translatesAutoresizingMaskIntoConstraints = false

        let root = UIStackView(arrangedSubviews: [headerContainer, webview])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webview.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let key = "mik_yeBk0Vf0nNJtpesfu560e07e5"
        let secret = "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022"
        let mapId = "660c0c6e7c0c4fe5b4cc484c"

        let options = GetMapDataWithCredentialsOptions(key: key, secret: secret, mapId: mapId)

        mapView.getMapData(options: options) { [weak self] result in
            switch result {
            case .success:
                let show = Show3DMapOptions()
                self?.mapView.show3dMap(options: show) { r2 in
                    switch r2 {
                    case .success:
                        DispatchQueue.main.async {
                            self?.loadingIndicator.stopAnimating()
                        }
                        self?.onMapLoaded()
                    case .failure(let e):
                        DispatchQueue.main.async {
                            self?.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap error: \(e)")
                    }
                }
            case .failure(let e):
                print("getMapData error: \(e)")
            }
        }
    }

    private func onMapLoaded() {
		mapView.on(Events.click) { [weak self] clickPayload in
			guard let self = self, let click = clickPayload, let label = click.labels?.first else { return }
			print("removing label: \(label.text)")
			self.mapView.labels.remove(label: label)
		}
		
        mapView.mapData.getByType(MapDataType.space) { [weak self] (result: Result<[Space], Error>) in
            switch result {
            case .success(let spaces):
                spaces.forEach { space in
                    guard !space.name.isEmpty else { return }
                    let color = self?.colors.randomElement()
                    let appearance = LabelAppearance(color: color, icon: space.images.first?.url ?? self?.svgIcon)
                    self?.mapView.labels.add(target: space, text: space.name, options: AddLabelOptions(labelAppearance: appearance, interactive: true))
                }
            case .failure(let e):
                print("getByType error: \(e)")
            }
        }
    }
}


