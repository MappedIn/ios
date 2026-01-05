import UIKit
import Mappedin

final class ColorsAndTexturesDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Colors & Textures"
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
            mapId: "64ef49e662fd90fe020bee61"
        )
        // Load the map data.
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                print("getMapData success")
                // Display the map with outdoor view and shadingAndOutlines disabled.
                let show3dOptions = Show3DMapOptions(
                    outdoorView: Show3DMapOptions.OutdoorViewOptions(
                        style: "https://tiles-cdn.mappedin.com/styles/midnightblue/style.json"
                    ),
                    shadingAndOutlines: false
                )
                self.mapView.show3dMap(options: show3dOptions) { r2 in
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
                print("getMapData error: \(error)")
            }
        }
    }

    // Apply textures and colors when the map is ready.
    // NOTE: Exterior wall texture is applied LAST for consistency with Android
    // (Android WebView has a texture loading issue that requires this ordering).
    private func onMapReady() {
        print("show3dMap success - Applying textures")

        // Get local asset URLs using mappedin-asset:// scheme for WebView access
        guard let exteriorWallURL = Bundle.main.mappedinAssetURL(forResource: "exterior-wall", withExtension: "jpg"),
              let floorURL = Bundle.main.mappedinAssetURL(forResource: "floor", withExtension: "png"),
              let objectSideURL = Bundle.main.mappedinAssetURL(forResource: "object-side", withExtension: "jpg") else {
            print("Error: Could not find texture assets")
            return
        }

        // Make interior doors visible, sides brown and top yellow
        mapView.updateState(
            doors: .interior,
            state: DoorsUpdateState(
                color: "brown",
                opacity: 0.6,
                visible: true,
                topColor: "yellow"
            )
        )

        // Make exterior doors visible, sides black and top blue
        mapView.updateState(
            doors: .exterior,
            state: DoorsUpdateState(
                color: "black",
                opacity: 0.6,
                visible: true,
                topColor: "blue"
            )
        )

        // Update all spaces with floor texture
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let spaces):
                for space in spaces {
                    self.mapView.updateState(
                        space: space,
                        state: GeometryUpdateState(
                            topTexture: GeometryUpdateState.Texture(url: floorURL)
                        )
                    )
                }
            case .failure(let error):
                print("Error getting spaces: \(error)")
            }
        }

        // Update all objects with side texture and top color
        mapView.mapData.getByType(.mapObject) { [weak self] (result: Result<[MapObject], Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let objects):
                for object in objects {
                    self.mapView.updateState(
                        mapObject: object,
                        state: GeometryUpdateState(
                            texture: GeometryUpdateState.Texture(url: objectSideURL),
                            topColor: "#9DB2BF"
                        )
                    )
                }
            case .failure(let error):
                print("Error getting objects: \(error)")
            }
        }

        // Update interior walls with colors
        mapView.updateState(
            walls: .interior,
            state: WallsUpdateState(
                color: "#526D82",
                topColor: "#27374D"
            )
        )
        
        // Update exterior walls with textures
        mapView.updateState(
            walls: .exterior,
            state: WallsUpdateState(
                texture: WallsTexture(url: exteriorWallURL),
                topTexture: WallsTexture(url: exteriorWallURL)
            )
        )
    }
}

