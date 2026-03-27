import UIKit
import Mappedin

/// Demonstrates caching map data for offline use. This example can work well on small to medium
/// sized maps or when map data needs to be manually modified. Loading the map from an MVF file
/// is much more efficient and recommended for larger maps. Refer to the CacheMVFDemoViewController and
/// OfflineModeDemoViewControler for examples of this. Use the load time stats printed out from these
/// demos to help make the best choice for your map.
///
/// **Enterprise maps:** `hydrateMapData` must receive the same shape as ``BinaryBundle/toJson()`` —
/// especially `options.enterprise` and any `languagePacks`. This demo saves a small manifest plus
/// binary files instead of only `bundle.main`, so Enterprise offline load works. If you previously
/// cached only `.bin`, a fallback sets `enterprise` from your API key (non-`mik_` keys are CMS).
///
/// This demo shows how to:
/// 1. Check if map data is cached locally
/// 2. Load from cache using hydrateMapData if available (full bundle shape)
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
    private static let manifestSuffix = ".manifest.json"

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
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let mapContainer = mapView.view
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mapContainer)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        view.addSubview(topBar)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .left
        statusLabel.textColor = .black
        statusLabel.numberOfLines = 0
        topBar.addSubview(statusLabel)

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

        if let backup = loadHydrateBackupFromCache(mapId: mapId, options: options) {
            print("CacheMapDataDemo: Using cached map data for \(mapId)")
            updateStatus("Loading from cache...")
            loadFromCachedBackup(backup, options: options)
        } else {
            print("CacheMapDataDemo: Fetching map data from server for \(mapId)")
            updateStatus("Fetching from server...")
            fetchFromServer(options: options)
        }
    }

    private func loadFromCachedBackup(_ backup: [String: Any], options: GetMapDataWithCredentialsOptions) {
        loadStartTime = CFAbsoluteTimeGetCurrent()
        let hydrateStartTime = CFAbsoluteTimeGetCurrent()

        mapView.hydrateMapData(backup: backup, options: options) { [weak self] result in
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
                self.deleteFromCache(mapId: options.mapId)
                self.updateStatus("Cache invalid, fetching from server...")
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
                guard let bundle = bundle else {
                    print("CacheMapDataDemo: toBinaryBundle returned nil")
                    return
                }
                do {
                    try self.writeBinaryCache(bundle: bundle, mapId: mapId)
                    print("CacheMapDataDemo: Map data cached (enterprise=\(bundle.enterprise), langPacks=\(bundle.languagePacks.count))")
                    self.updateStatus("Cached for offline use!")
                } catch {
                    print("CacheMapDataDemo: Failed to save cache: \(error)")
                }
            case .failure(let error):
                print("CacheMapDataDemo: toBinaryBundle error: \(error)")
            }
        }
    }

    private func writeBinaryCache(bundle: BinaryBundle, mapId: String) throws {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let mainName = "\(Self.cacheFilePrefix)\(mapId).bin"
        let mainURL = caches.appendingPathComponent(mainName)
        try bundle.main.write(to: mainURL)

        var langRefs: [BinaryCacheManifest.LanguageFileRef] = []
        for pack in bundle.languagePacks {
            let safeCode = Self.sanitizedFileComponent(pack.code)
            let fileName = "\(Self.cacheFilePrefix)\(mapId)-lang-\(safeCode).bin"
            let fileURL = caches.appendingPathComponent(fileName)
            try pack.data.write(to: fileURL)
            langRefs.append(BinaryCacheManifest.LanguageFileRef(code: pack.code, name: pack.name, fileName: fileName))
        }

        let manifest = BinaryCacheManifest(
            version: BinaryCacheManifest.currentVersion,
            enterprise: bundle.enterprise,
            mainFileName: mainName,
            languagePacks: langRefs
        )
        let manifestURL = caches.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId)\(Self.manifestSuffix)")
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: manifestURL)
        print("CacheMapDataDemo: Wrote cache main=\(mainName) (\(bundle.main.count) bytes), manifest=\(manifestURL.lastPathComponent)")
    }

    private func loadHydrateBackupFromCache(mapId: String, options: GetMapDataWithCredentialsOptions) -> [String: Any]? {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let manifestURL = caches.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId)\(Self.manifestSuffix)")
        let mainURL = getMainCacheFileURL(mapId: mapId)

        if FileManager.default.fileExists(atPath: manifestURL.path) {
            do {
                let manifestData = try Data(contentsOf: manifestURL)
                let manifest = try JSONDecoder().decode(BinaryCacheManifest.self, from: manifestData)
                guard manifest.version == BinaryCacheManifest.currentVersion else {
                    print("CacheMapDataDemo: Unknown cache manifest version \(manifest.version)")
                    return nil
                }
                let mainData = try Data(contentsOf: caches.appendingPathComponent(manifest.mainFileName))
                var languagePacks: [[String: Any]] = []
                for ref in manifest.languagePacks {
                    let packURL = caches.appendingPathComponent(ref.fileName)
                    let packData = try Data(contentsOf: packURL)
                    languagePacks.append([
                        "language": ["code": ref.code, "name": ref.name],
                        "localePack": [UInt8](packData).map { Int($0) },
                    ])
                }
                print("CacheMapDataDemo: Loaded cache from manifest (enterprise=\(manifest.enterprise), langPacks=\(languagePacks.count))")
                return hydrateBackupBinary(
                    main: mainData,
                    enterprise: manifest.enterprise,
                    languagePacks: languagePacks
                )
            } catch {
                print("CacheMapDataDemo: Failed to load manifest cache: \(error)")
                return nil
            }
        }

        guard FileManager.default.fileExists(atPath: mainURL.path) else {
            print("CacheMapDataDemo: No cached data found for \(mapId)")
            return nil
        }
        do {
            let mainData = try Data(contentsOf: mainURL)
            let enterpriseInferred = !options.key.hasPrefix("mik_")
            print("CacheMapDataDemo: Legacy .bin only — using enterprise=\(enterpriseInferred) from key prefix")
            return hydrateBackupBinary(main: mainData, enterprise: enterpriseInferred, languagePacks: [])
        } catch {
            print("CacheMapDataDemo: Failed to load cache: \(error)")
            return nil
        }
    }

    private func hydrateBackupBinary(main: Data, enterprise: Bool, languagePacks: [[String: Any]]) -> [String: Any] {
        let mainArray = [UInt8](main).map { Int($0) }
        var backup: [String: Any] = [
            "type": "binary",
            "main": mainArray,
            "options": [
                "enterprise": enterprise,
            ],
        ]
        if !languagePacks.isEmpty {
            backup["languagePacks"] = languagePacks
        }
        return backup
    }

    private func deleteFromCache(mapId: String) {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let manifestURL = caches.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId)\(Self.manifestSuffix)")

        if FileManager.default.fileExists(atPath: manifestURL.path),
           let manifestData = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode(BinaryCacheManifest.self, from: manifestData) {
            let urls = [manifestURL, caches.appendingPathComponent(manifest.mainFileName)]
                + manifest.languagePacks.map { caches.appendingPathComponent($0.fileName) }
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
            print("CacheMapDataDemo: Deleted manifest cache for \(mapId)")
            return
        }

        let legacyMain = getMainCacheFileURL(mapId: mapId)
        try? FileManager.default.removeItem(at: legacyMain)
        try? FileManager.default.removeItem(at: manifestURL)
        print("CacheMapDataDemo: Deleted cached data for \(mapId)")
    }

    private func getMainCacheFileURL(mapId: String) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("\(Self.cacheFilePrefix)\(mapId).bin")
    }

    private static func sanitizedFileComponent(_ code: String) -> String {
        code.map { ch in
            ch.isLetter || ch.isNumber ? String(ch) : "_"
        }.joined()
    }

    private func recreateMapView() {
        mapView.view.removeFromSuperview()
        mapView.destroy()
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

private struct BinaryCacheManifest: Codable {
    static let currentVersion = 1

    var version: Int
    var enterprise: Bool
    var mainFileName: String
    var languagePacks: [LanguageFileRef]

    struct LanguageFileRef: Codable {
        var code: String
        var name: String
        var fileName: String
    }
}
