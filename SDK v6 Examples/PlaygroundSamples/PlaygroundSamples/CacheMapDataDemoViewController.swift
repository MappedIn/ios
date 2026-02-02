import UIKit
import Mappedin

/// Demonstrates caching map data for offline use. This example can work well on small to medium
/// sized maps or when map data needs to be manually modified. Loading the map from an MVF file
/// is much more efficient and recommended for larger maps. Refer to the CacheMVFDemoViewController and
/// OfflineModeDemoViewControler for examples of this. Use the load time stats printed out from these
/// demos to help make the best choice for your map.
///
/// This demo shows how to:
/// 1. Check if map data is cached locally
/// 2. Load from cache using hydrateMapData if available
/// 3. Fetch from server using getMapData if not cached
/// 4. Save the fetched data to cache using toBinaryBundle
///
/// The cached data is stored in the app's caches directory.
final class CacheMapDataDemoViewController: UIViewController {
    private var mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let clearCacheButton = UIButton(type: .system)
    private let topBar = UIView()
    private let container = UIView()
    private var currentMapId: String = ""

    private static let cacheFilePrefix = "cached-map-"
    private var loadStartTime: CFAbsoluteTime = 0
    private var dataLoadDuration: Double = 0
    private var isCachedLoad: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cache Map Data"
        view.backgroundColor = .systemBackground

        setupUI()
        loadMapData()
    }

    private func setupUI() {
        // Add map view container
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let mapContainer = mapView.view
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mapContainer)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        // Add top bar with status and clear cache button
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        view.addSubview(topBar)

        // Add status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .left
        statusLabel.textColor = .black
        statusLabel.numberOfLines = 0
        topBar.addSubview(statusLabel)

        // Add clear cache button
        clearCacheButton.translatesAutoresizingMaskIntoConstraints = false
        clearCacheButton.setTitle("Clear Cache", for: .normal)
        clearCacheButton.addTarget(self, action: #selector(onClearCacheClicked), for: .touchUpInside)
        topBar.addSubview(clearCacheButton)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mapContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mapContainer.topAnchor.constraint(equalTo: container.topAnchor),
            mapContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 8),
            statusLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -8),

            clearCacheButton.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 8),
            clearCacheButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            clearCacheButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            clearCacheButton.widthAnchor.constraint(equalToConstant: 100),
        ])
    }

    @objc private func onClearCacheClicked() {
        guard !currentMapId.isEmpty else { return }
        deleteFromCache(mapId: currentMapId)
        updateStatus("Cache cleared! Restart to reload.")
    }

    private func loadMapData() {
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "67a6641530e940000bac3c1a"
        )

        let mapId = options.mapId
        currentMapId = mapId

        // Check if there is cached data for this map
        if let cachedData = loadFromCache(mapId: mapId) {
            print("CacheMapDataDemo: Using cached map data for \(mapId)")
            updateStatus("Loading from cache...")
            loadFromCachedData(cachedData, options: options)
        } else {
            print("CacheMapDataDemo: Fetching map data from server for \(mapId)")
            updateStatus("Fetching from server...")
            fetchFromServer(options: options)
        }
    }

    private func loadFromCachedData(_ cachedData: Data, options: GetMapDataWithCredentialsOptions) {
        loadStartTime = CFAbsoluteTimeGetCurrent()

        // Create the backup object in the format expected by hydrateMapData
        let mainArray = [UInt8](cachedData).map { Int($0) }
        let backupObject: [String: Any] = [
            "type": "binary",
            "main": mainArray
        ]

        let hydrateStartTime = CFAbsoluteTimeGetCurrent()

        mapView.hydrateMapData(backup: backupObject, options: options) { [weak self] result in
            guard let self = self else { return }

            let hydrateEndTime = CFAbsoluteTimeGetCurrent()
            let hydrateDuration = (hydrateEndTime - hydrateStartTime) * 1000

            switch result {
            case .success:
                print("CacheMapDataDemo: hydrateMapData success - loaded from cache in \(String(format: "%.0f", hydrateDuration))ms")
                self.updateStatus("Loaded from cache!")
                self.dataLoadDuration = hydrateDuration
                self.isCachedLoad = true
                self.showMap()
            case .failure(let error):
                print("CacheMapDataDemo: hydrateMapData error: \(error) (after \(String(format: "%.0f", hydrateDuration))ms)")
                // If cache is corrupted, delete it and fetch fresh data
                self.deleteFromCache(mapId: options.mapId)
                self.updateStatus("Cache invalid, fetching from server...")

                // Create a new MapView since hydrateMapData can only be called once
                self.recreateMapView()
                self.fetchFromServer(options: options)
            }
        }
    }

    private func fetchFromServer(options: GetMapDataWithCredentialsOptions) {
        loadStartTime = CFAbsoluteTimeGetCurrent()
        let getMapDataStartTime = CFAbsoluteTimeGetCurrent()

        mapView.getMapData(options: options) { [weak self] result in
            guard let self = self else { return }

            let getMapDataEndTime = CFAbsoluteTimeGetCurrent()
            let getMapDataDuration = (getMapDataEndTime - getMapDataStartTime) * 1000

            switch result {
            case .success:
                print("CacheMapDataDemo: getMapData success - fetched from server in \(String(format: "%.0f", getMapDataDuration))ms")
                self.updateStatus("Fetched from server...")

                self.dataLoadDuration = getMapDataDuration
                self.isCachedLoad = false
                // Cache saving is deferred until after show3dMap to avoid blocking the render
                self.showMap(mapIdToCache: options.mapId)
            case .failure(let error):
                print("CacheMapDataDemo: getMapData error: \(error) (after \(String(format: "%.0f", getMapDataDuration))ms)")
                self.hideLoading()
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }

    private func showMap(mapIdToCache: String? = nil) {
        let show3dMapStartTime = CFAbsoluteTimeGetCurrent()

        mapView.show3dMap(options: Show3DMapOptions()) { [weak self] result in
            guard let self = self else { return }

            let show3dMapEndTime = CFAbsoluteTimeGetCurrent()
            let show3dMapDuration = (show3dMapEndTime - show3dMapStartTime) * 1000
            let totalDuration = (show3dMapEndTime - self.loadStartTime) * 1000
            let source = self.isCachedLoad ? "CACHE" : "NETWORK"

            switch result {
            case .success:
                self.hideLoading()
                print("CacheMapDataDemo: show3dMap success - took \(String(format: "%.0f", show3dMapDuration))ms")
                print("CacheMapDataDemo: === TOTAL MAP LOAD TIME (\(source)): \(String(format: "%.0f", totalDuration))ms (data: \(String(format: "%.0f", self.dataLoadDuration))ms, show3dMap: \(String(format: "%.0f", show3dMapDuration))ms) ===")
                self.onMapReady()

                // Save to cache after map is displayed to avoid blocking the render
                if let mapId = mapIdToCache {
                    print("CacheMapDataDemo: Starting background cache save...")
                    self.saveToCache(mapId: mapId)
                }
            case .failure(let error):
                self.hideLoading()
                print("CacheMapDataDemo: show3dMap error: \(error) (after \(String(format: "%.0f", show3dMapDuration))ms)")
                self.updateStatus("Error displaying map: \(error.localizedDescription)")
            }
        }
    }

    private func onMapReady() {
        print("CacheMapDataDemo: Map displayed successfully")

        // Add labels to all named spaces
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }

            if case .success(let spaces) = result {
                spaces.filter { !$0.name.isEmpty }.forEach { space in
                    self.mapView.labels.add(target: space, text: space.name, options: AddLabelOptions(interactive: true)) { _ in }
                }
            }
        }
    }

    private func saveToCache(mapId: String) {
        mapView.mapData.toBinaryBundle(downloadLanguagePacks: true) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let bundle):
                if let bundle = bundle {
                    do {
                        let cacheFileURL = self.getCacheFileURL(mapId: mapId)
                        try bundle.main.write(to: cacheFileURL)
                        print("CacheMapDataDemo: Map data cached successfully to \(cacheFileURL.path)")
                        print("CacheMapDataDemo: Cache size: \(bundle.main.count) bytes")
                        self.updateStatus("Cached for offline use!")
                    } catch {
                        print("CacheMapDataDemo: Failed to save cache: \(error)")
                    }
                } else {
                    print("CacheMapDataDemo: toBinaryBundle returned nil")
                }
            case .failure(let error):
                print("CacheMapDataDemo: toBinaryBundle error: \(error)")
            }
        }
    }

    private func loadFromCache(mapId: String) -> Data? {
        let cacheFileURL = getCacheFileURL(mapId: mapId)

        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            print("CacheMapDataDemo: No cached data found for \(mapId)")
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            print("CacheMapDataDemo: Found cached data at \(cacheFileURL.path)")
            print("CacheMapDataDemo: Cache size: \(data.count) bytes")
            return data
        } catch {
            print("CacheMapDataDemo: Failed to load cache: \(error)")
            return nil
        }
    }

    private func deleteFromCache(mapId: String) {
        let cacheFileURL = getCacheFileURL(mapId: mapId)

        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: cacheFileURL)
            print("CacheMapDataDemo: Deleted cached data for \(mapId)")
        } catch {
            print("CacheMapDataDemo: Failed to delete cache: \(error)")
        }
    }

    private func getCacheFileURL(mapId: String) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId).bin")
    }

    private func recreateMapView() {
        // Remove old map view
        mapView.view.removeFromSuperview()

        // Destroy the old MapView to release WKWebView resources and prevent memory leaks
        mapView.destroy()

        // Create new map view
        mapView = MapView()
        let mapContainer = mapView.view
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mapContainer)

        NSLayoutConstraint.activate([
            mapContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mapContainer.topAnchor.constraint(equalTo: container.topAnchor),
            mapContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = "  \(message)  "
            self.statusLabel.isHidden = false
        }
    }

    private func hideLoading() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
        }
    }
}
