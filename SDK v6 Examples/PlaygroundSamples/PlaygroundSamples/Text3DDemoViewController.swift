import UIKit
import Mappedin

final class Text3DDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let colors = [
        "#ff0000",
        "#0000ff",
        "#008000",
        "#ffff00",
        "#800080",
        "#ffa500",
        "#ffc0cb",
        "#00ffff",
        "#ffffff",
        "#000000",
    ]

    private func getRandomColor() -> String {
        colors.randomElement() ?? "#ffffff"
    }

    private func getRandomFontSize() -> Double {
		let min = 5.0
        let max = 8.0
        return Double.random(in: min...max)
    }

    private func getRandomRotation() -> Double {
        Double.random(in: 0..<360)
    }

    private func getRandomWidth() -> Double {
        Double.random(in: 0...1)
    }

    private func getRandomStrokeWidth() -> Double {
        Double.random(in: 0...0.1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white
        title = "Text3D"

        // Header UI (title + description) above the map
        let headerContainer = UIStackView()
        headerContainer.axis = .vertical
        headerContainer.spacing = 6
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Text3D"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Click anywhere on the map to place text with random appearance settings."
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
        // https://developer.mappedin.com/web/v6/trial-keys-and-maps/
        let key = "mik_yeBk0Vf0nNJtpesfu560e07e5"
        let secret = "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022"
        let mapId = "6679882a8298d5000b85ee89"

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
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                }
                print("getMapData error: \(e)")
            }
        }
    }

    private func onMapLoaded() {
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self = self,
                  let click = clickPayload else { return }
            let coordinate = click.coordinate

            // Generate random appearance settings
            let fontSize = self.getRandomFontSize()
            let color = self.getRandomColor()
            let outlineWidth = self.getRandomWidth()
            let outlineColor = self.getRandomColor()
            let strokeWidth = self.getRandomStrokeWidth()
            let strokeColor = self.getRandomColor()
            let rotation = self.getRandomRotation()

            let appearance = InitializeText3DState(
                color: color,
                fontSize: fontSize,
                outlineColor: outlineColor,
                outlineWidth: outlineWidth,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth
            )

            let options = AddText3DPointOptions(
                appearance: appearance,
                rotation: rotation
            )

            // Log the appearance settings
            print("Adding Text3D with: fontSize=\(String(format: "%.2f", fontSize)), color=\(color), outlineWidth=\(String(format: "%.2f", outlineWidth)), outlineColor=\(outlineColor), strokeWidth=\(String(format: "%.3f", strokeWidth)), strokeColor=\(strokeColor), rotation=\(String(format: "%.0f", rotation))°")

            self.mapView.text3D.add(
                target: coordinate,
                content: "Hello, world!",
                options: options
            ) { result in
                switch result {
                case .success(let text3DView):
                    if let view = text3DView {
                        print("Text3D added with id: \(view.id)")
                    }
                case .failure(let error):
                    print("Failed to add Text3D: \(error)")
                }
            }
        }
    }
}
