import UIKit
import Mappedin

struct ModelData: Codable {
    let id: String
    let modelId: String
    let coordinate: ModelCoordinate
    let rotation: [Double]
    let scale: [Double]
    let color: String
    let verticalOffset: Double
}

struct ModelCoordinate: Codable {
    let latitude: Double
    let longitude: Double
    let verticalOffset: Double
    let floorId: String
}

struct ModelsData: Codable {
    let models: [ModelData]
    let version: String
    let timestamp: Int
}

final class ModelsDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Models"
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
        // Load model positions from JSON file in bundle
        // The JSON file was created using Mappedin 3D Model Mapper: https://developer.mappedin.com/docs/tools/3d-model-mapper
        guard let modelsData = loadModelsFromJSON() else {
            print("Failed to load model_positions.json")
            return
        }

        // Get all floors for lookup
        mapView.mapData.getByType(.floor) { [weak self] (result: Result<[Floor], Error>) in
            guard let self = self else { return }

            switch result {
            case .success(let floors):
                let floorMap = Dictionary(uniqueKeysWithValues: floors.map { ($0.id, $0) })

                // Add each model from the JSON
                for modelData in modelsData.models {
                    self.addModelFromData(modelData: modelData, floorMap: floorMap)
                }

            case .failure(let error):
                print("Failed to get floors: \(error)")
            }
        }

        // Remove models that are clicked on
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self = self,
                  let clickedModel = clickPayload?.models?.first else { return }

            self.mapView.models.remove(model: clickedModel) { _ in }
        }
    }

    private func addModelFromData(modelData: ModelData, floorMap: [String: Floor]) {
        // Verify the floor exists
        guard floorMap[modelData.coordinate.floorId] != nil else {
            print("Floor not found: \(modelData.coordinate.floorId)")
            return
        }

        // Create coordinate
        let coordinate = Coordinate(latitude: modelData.coordinate.latitude, longitude: modelData.coordinate.longitude)

        // Get model URL from bundle
        guard let modelUrl = getModelUrl(modelId: modelData.modelId) else {
            print("Model not found: \(modelData.modelId)")
            return
        }

        // Create scale
        let scale: AddModelOptions.Scale = .perAxis(x: modelData.scale[0], y: modelData.scale[1], z: modelData.scale[2])

        // Create material colors
        let materialColors: [String: AddModelOptions.MaterialStyle] = [
            "Default": AddModelOptions.MaterialStyle(color: modelData.color),
            "Fabric": AddModelOptions.MaterialStyle(color: modelData.color),
            "Mpdn_Logo": AddModelOptions.MaterialStyle(color: modelData.color)
        ]

        // Create options
        let opts = AddModelOptions(
            interactive: true,
            visible: true,
            opacity: 1.0,
            material: materialColors,
            verticalOffset: modelData.coordinate.verticalOffset,
            color: nil,
            visibleThroughGeometry: false,
            rotation: modelData.rotation,
            scale: scale
        )

        // Add the model
		mapView.models.add(coordinate: coordinate, url: modelUrl, options: opts) { _ in }
    }

    private func getModelUrl(modelId: String) -> String? {
        // Try with 3d_assets subdirectory first (folder reference)
        if let assetUrl = Bundle.main.mappedinAssetURL(forResource: modelId, withExtension: "glb", subdirectory: "3d_assets") {
            return assetUrl
        }
        // Fall back to bundle root (files added directly or folder added as group)
        if let assetUrl = Bundle.main.mappedinAssetURL(forResource: modelId, withExtension: "glb") {
            return assetUrl
        }

        print("Failed to find \(modelId).glb in bundle. Make sure 3d_assets folder is added to the Xcode project.")
        return nil
    }

    private func loadModelsFromJSON() -> ModelsData? {
        guard let path = Bundle.main.path(forResource: "model_positions", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(ModelsData.self, from: data)
    }
}


