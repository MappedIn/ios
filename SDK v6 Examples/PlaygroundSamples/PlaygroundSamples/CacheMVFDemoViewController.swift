import UIKit
import Mappedin

/// Demonstrates downloading and caching MVF data using Mappedin's REST API.
///
/// This demo shows how to:
/// 1. Check if MVF data is cached locally
/// 2. Download MVF bundle via REST API if not cached
/// 3. Load from cache using hydrateMapData
/// 4. Save the downloaded MVF to cache for offline use
///
/// The MVF is downloaded from:
/// - Token endpoint: https://app.mappedin.com/api/v1/api-key/token
/// - MVF endpoint: https://app.mappedin.com/api/venue/{mapId}/mvf?version=3.0.0
final class CacheMVFDemoViewController: UIViewController {
    private var mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let clearCacheButton = UIButton(type: .system)
    private let topBar = UIView()
    private let container = UIView()
    private var currentMapId: String = ""

    private static let cacheFilePrefix = "cached-mvf-"

    // API credentials (Demo API key)
    // See Trial API key Terms and Conditions: https://developer.mappedin.com/docs/demo-keys-and-maps
    private static let mappedinKey = "mik_yeBk0Vf0nNJtpesfu560e07e5"
    private static let mappedinSecret = "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022"

    // Map ID from the Mapkit JS example
    private static let mapId = "67a6641530e940000bac3c1a"

    // Timing tracking
    private var loadStartTime: CFAbsoluteTime = 0
    private var dataLoadDuration: Double = 0
    private var isCachedLoad: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cache MVF Data"
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
        currentMapId = Self.mapId
        loadStartTime = CFAbsoluteTimeGetCurrent()

        // Check if there is cached MVF data for this map
        if let cachedData = loadFromCache(mapId: Self.mapId) {
            print("CacheMVFDemo: Using cached MVF data for \(Self.mapId)")
            updateStatus("Loading from cache...")
            isCachedLoad = true
            loadFromCachedData(cachedData)
        } else {
            print("CacheMVFDemo: Downloading MVF data from REST API for \(Self.mapId)")
            updateStatus("Downloading MVF via REST API...")
            isCachedLoad = false
            downloadMvfFromApi()
        }
    }

    private func loadFromCachedData(_ cachedData: Data) {
        let hydrateStartTime = CFAbsoluteTimeGetCurrent()

        // Get the cache file name and create a mappedin-cache:// URL
        let cacheFileName = "\(Self.cacheFilePrefix)\(Self.mapId).zip"
        guard let cacheUrl = FileManager.default.mappedinCacheURL(forFileName: cacheFileName) else {
            print("CacheMVFDemo: Failed to create cache URL")
            deleteFromCache(mapId: Self.mapId)
            updateStatus("Cache invalid, downloading from API...")
            recreateMapView()
            downloadMvfFromApi()
            return
        }

        print("CacheMVFDemo: Loading from URL: \(cacheUrl)")

        // Pass credentials to enable outdoor view (tileset tokens require authentication)
        let options = GetMapDataWithCredentialsOptions(
            key: Self.mappedinKey,
            secret: Self.mappedinSecret,
            mapId: Self.mapId
        )

		// Use hydrateMapDataFromURL for faster loading compared to the CacheMapDataDemoActivity
		// - avoids passing large data over bridge
        mapView.hydrateMapDataFromURL(url: cacheUrl, options: options) { [weak self] result in
            guard let self = self else { return }

            let hydrateEndTime = CFAbsoluteTimeGetCurrent()
            self.dataLoadDuration = (hydrateEndTime - hydrateStartTime) * 1000

            switch result {
            case .success:
                print("CacheMVFDemo: hydrateMapDataFromURL success - loaded from cache in \(String(format: "%.0f", self.dataLoadDuration))ms")
                self.updateStatus("Loaded from cache!")
                self.showMap()
            case .failure(let error):
                print("CacheMVFDemo: hydrateMapDataFromURL error: \(error) (after \(String(format: "%.0f", self.dataLoadDuration))ms)")
                // If cache is corrupted, delete it and download fresh data
                self.deleteFromCache(mapId: Self.mapId)
                self.updateStatus("Cache invalid, downloading from API...")

                // Create a new MapView since hydrateMapData can only be called once
                self.recreateMapView()
                self.downloadMvfFromApi()
            }
        }
    }

    private func downloadMvfFromApi() {
        let downloadStartTime = CFAbsoluteTimeGetCurrent()

        Task {
            do {
                // Step 1: Get access token
                let tokenStartTime = CFAbsoluteTimeGetCurrent()
                let accessToken = try await getAccessToken()
                let tokenDuration = (CFAbsoluteTimeGetCurrent() - tokenStartTime) * 1000
                print("CacheMVFDemo: Got access token in \(String(format: "%.0f", tokenDuration))ms")

                await MainActor.run {
                    self.updateStatus("Got token, fetching MVF URL...")
                }

                // Step 2: Get MVF download URL
                let mvfUrlStartTime = CFAbsoluteTimeGetCurrent()
                let mvfUrl = try await getMvfUrl(accessToken: accessToken, mapId: Self.mapId)
                let mvfUrlDuration = (CFAbsoluteTimeGetCurrent() - mvfUrlStartTime) * 1000
                print("CacheMVFDemo: Got MVF URL in \(String(format: "%.0f", mvfUrlDuration))ms")

                await MainActor.run {
                    self.updateStatus("Downloading MVF bundle...")
                }

                // Step 3: Download the MVF zip file
                let downloadZipStartTime = CFAbsoluteTimeGetCurrent()
                let mvfData = try await downloadMvfZip(mvfUrl: mvfUrl)
                let downloadZipDuration = (CFAbsoluteTimeGetCurrent() - downloadZipStartTime) * 1000
                print("CacheMVFDemo: Downloaded MVF zip (\(mvfData.count) bytes) in \(String(format: "%.0f", downloadZipDuration))ms")

                let totalDownloadDuration = (CFAbsoluteTimeGetCurrent() - downloadStartTime) * 1000
                print("CacheMVFDemo: === TOTAL MVF DOWNLOAD TIME: \(String(format: "%.0f", totalDownloadDuration))ms (token: \(String(format: "%.0f", tokenDuration))ms, mvfUrl: \(String(format: "%.0f", mvfUrlDuration))ms, download: \(String(format: "%.0f", downloadZipDuration))ms) ===")

                await MainActor.run {
                    self.dataLoadDuration = totalDownloadDuration
                    self.updateStatus("Downloaded MVF, hydrating...")
                    self.hydrateMvfData(mvfData)
                }
            } catch {
                print("CacheMVFDemo: Error downloading MVF: \(error)")
                await MainActor.run {
                    self.hideLoading()
                    self.updateStatus("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func getAccessToken() async throws -> String {
        let url = URL(string: "https://app.mappedin.com/api/v1/api-key/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "key": Self.mappedinKey,
            "secret": Self.mappedinSecret
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["access_token"] as! String
    }

    private func getMvfUrl(accessToken: String, mapId: String) async throws -> String {
        let url = URL(string: "https://app.mappedin.com/api/venue/\(mapId)/mvf?version=3.0.0")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["url"] as! String
    }

    private func downloadMvfZip(mvfUrl: String) async throws -> Data {
        let url = URL(string: mvfUrl)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private func hydrateMvfData(_ mvfData: Data) {
        let hydrateStartTime = CFAbsoluteTimeGetCurrent()

        // First save to cache, then load via URL for optimal performance
        saveToCache(mapId: Self.mapId, data: mvfData)

        // Pass credentials to enable outdoor view (tileset tokens require authentication)
        let options = GetMapDataWithCredentialsOptions(
            key: Self.mappedinKey,
            secret: Self.mappedinSecret,
            mapId: Self.mapId
        )

        // Get the cache file name and create a mappedin-cache:// URL
        let cacheFileName = "\(Self.cacheFilePrefix)\(Self.mapId).zip"
        guard let cacheUrl = FileManager.default.mappedinCacheURL(forFileName: cacheFileName) else {
            print("CacheMVFDemo: Failed to create cache URL, falling back to binary method")
            // Fall back to binary method if URL creation fails
            let mainArray = [UInt8](mvfData).map { Int($0) }
            let backupObject: [String: Any] = [
                "type": "binary",
                "main": mainArray
            ]
            mapView.hydrateMapData(backup: backupObject, options: options) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.showMap()
                case .failure(let error):
                    self.hideLoading()
                    self.updateStatus("Error: \(error.localizedDescription)")
                }
            }
            return
        }

        print("CacheMVFDemo: Hydrating from URL: \(cacheUrl)")

        // Use hydrateMapDataFromURL for faster loading
        mapView.hydrateMapDataFromURL(url: cacheUrl, options: options) { [weak self] result in
            guard let self = self else { return }

            let hydrateEndTime = CFAbsoluteTimeGetCurrent()
            let hydrateDuration = (hydrateEndTime - hydrateStartTime) * 1000
            print("CacheMVFDemo: hydrateMapDataFromURL took \(String(format: "%.0f", hydrateDuration))ms")

            switch result {
            case .success:
                print("CacheMVFDemo: hydrateMapDataFromURL success")
                self.updateStatus("Hydrated, displaying map...")
                self.showMap()
            case .failure(let error):
                print("CacheMVFDemo: hydrateMapDataFromURL error: \(error)")
                self.hideLoading()
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }

    private func showMap() {
        let show3dMapStartTime = CFAbsoluteTimeGetCurrent()

        mapView.show3dMap(options: Show3DMapOptions()) { [weak self] result in
            guard let self = self else { return }

            let show3dMapEndTime = CFAbsoluteTimeGetCurrent()
            let show3dMapDuration = (show3dMapEndTime - show3dMapStartTime) * 1000
            let totalDuration = (show3dMapEndTime - self.loadStartTime) * 1000
            let source = self.isCachedLoad ? "CACHE" : "REST_API"

            switch result {
            case .success:
                self.hideLoading()
                print("CacheMVFDemo: show3dMap success - took \(String(format: "%.0f", show3dMapDuration))ms")
                print("CacheMVFDemo: === TOTAL MAP LOAD TIME (\(source)): \(String(format: "%.0f", totalDuration))ms (data: \(String(format: "%.0f", self.dataLoadDuration))ms, show3dMap: \(String(format: "%.0f", show3dMapDuration))ms) ===")
                self.updateStatus("Map loaded from \(source)!")
                self.onMapReady()
            case .failure(let error):
                self.hideLoading()
                print("CacheMVFDemo: show3dMap error: \(error) (after \(String(format: "%.0f", show3dMapDuration))ms)")
                self.updateStatus("Error displaying map: \(error.localizedDescription)")
            }
        }
    }

    private func onMapReady() {
        print("CacheMVFDemo: Map displayed successfully")

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

    private func saveToCache(mapId: String, data: Data) {
        do {
            let cacheFileURL = getCacheFileURL(mapId: mapId)
            try data.write(to: cacheFileURL)
            print("CacheMVFDemo: MVF data cached successfully to \(cacheFileURL.path)")
            print("CacheMVFDemo: Cache size: \(data.count) bytes")
        } catch {
            print("CacheMVFDemo: Failed to save cache: \(error)")
        }
    }

    private func loadFromCache(mapId: String) -> Data? {
        let cacheFileURL = getCacheFileURL(mapId: mapId)

        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            print("CacheMVFDemo: No cached MVF data found for \(mapId)")
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            print("CacheMVFDemo: Found cached MVF data at \(cacheFileURL.path)")
            print("CacheMVFDemo: Cache size: \(data.count) bytes")
            return data
        } catch {
            print("CacheMVFDemo: Failed to load cache: \(error)")
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
            print("CacheMVFDemo: Deleted cached MVF data for \(mapId)")
        } catch {
            print("CacheMVFDemo: Failed to delete cache: \(error)")
        }
    }

    private func getCacheFileURL(mapId: String) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId).zip")
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
