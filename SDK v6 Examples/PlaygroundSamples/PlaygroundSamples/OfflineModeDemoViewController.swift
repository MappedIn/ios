import UIKit
import Mappedin

final class OfflineModeDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Offline Mode"
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

        // Load the MVFv3 zip file from bundle
        guard let zipData = loadMvfFromBundle(fileName: "school-demo-multifloor-mvfv3", extension: "zip") else {
            print("Failed to load MVF file from bundle")
            loadingIndicator.stopAnimating()
            return
        }

        // Create the backup object in the format expected by hydrateMapData
        // { type: "binary", main: <array of bytes> }
        let mainArray = [UInt8](zipData).map { Int($0) }
        let backupObject: [String: Any] = [
            "type": "binary",
            "main": mainArray
        ]

        // Hydrate the map data from the local MVF file
        mapView.hydrateMapData(backup: backupObject) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("hydrateMapData success")
                // Display the map
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    switch r2 {
                    case .success:
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        self.onMapReady()
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap error: \(error)")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                print("hydrateMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        print("show3dMap success - Map displayed from offline MVF")

        // Add labels to all named spaces to demonstrate the map is fully functional
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }

            if case .success(let spaces) = result {
                spaces.filter { !$0.name.isEmpty }.forEach { space in
                    self.mapView.labels.add(target: space, text: space.name, options: AddLabelOptions(interactive: true)) { _ in }
                }
            }
        }
    }

    private func loadMvfFromBundle(fileName: String, extension ext: String) -> Data? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: ext) else {
            print("MVF file not found in bundle: \(fileName).\(ext)")
            return nil
        }

        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            print("Error loading MVF file: \(error)")
            return nil
        }
    }
}
