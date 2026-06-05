import UIKit
import Mappedin

/// Demonstrates loading a single `MapView` once and reusing it across several
/// screens. Each tab is a separate `ReusableMapScreenViewController`, and the
/// one shared map's WebView is physically reparented into whichever screen is
/// currently visible.
///
/// Because the underlying WebView boots, downloads the venue, and renders only
/// once, switching tabs is instant: the map is moved into the new screen and
/// the camera is re-focused, rather than creating and loading a brand new map.
final class ReusableMapViewDemoViewController: UITabBarController {
    private let mapView = MapView()

    /// True once the map has loaded and rendered for the first time.
    private(set) var isMapReady = false

    /// True if loading the map data or rendering it failed.
    private(set) var loadFailed = false

    /// Spaces from the loaded venue, used to pick a focus target per screen.
    private var spaces: [Space] = []

    private let screenTitles = ["Screen 1", "Screen 2", "Screen 3"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reusable MapView"
        view.backgroundColor = .systemBackground

        viewControllers = screenTitles.enumerated().map { index, screenTitle in
            let screen = ReusableMapScreenViewController(host: self, screenIndex: index, screenTitle: screenTitle)
            screen.tabBarItem = UITabBarItem(title: screenTitle, image: UIImage(systemName: "map"), tag: index)
            return screen
        }

        loadMap()
    }

    private func loadMap() {
        // See Demo API Key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "660c0c6e7c0c4fe5b4cc484c"
        )

        mapView.getMapData(options: options) { [weak self] dataResult in
            guard let self else { return }
            guard case .success = dataResult else {
                self.handleLoadFailure()
                return
            }
            self.mapView.show3dMap(options: Show3DMapOptions()) { [weak self] showResult in
                guard let self else { return }
                guard case .success = showResult else {
                    self.handleLoadFailure()
                    return
                }
                // Automatically add default labels and markers so the map
                // looks complete on its first and only load.
                self.mapView.__EXPERIMENTAL__auto()
                // The map is rendered now, so mark it ready and hide the loading
                // indicator. Focusing depends on the spaces query below, which is
                // loaded separately so a failure there never leaves the screen
                // stuck on the spinner.
                DispatchQueue.main.async {
                    self.isMapReady = true
                    self.notifySelectedScreen()
                }
                self.mapView.mapData.getByType(.space) { [weak self] (spacesResult: Result<[Space], Error>) in
                    guard let self, case .success(let loaded) = spacesResult else { return }
                    DispatchQueue.main.async {
                        self.spaces = loaded.filter { !$0.name.isEmpty }
                        // Refresh the active screen so its header and camera
                        // reflect the loaded spaces.
                        self.notifySelectedScreen()
                    }
                }
            }
        }
    }

    private func handleLoadFailure() {
        DispatchQueue.main.async {
            self.loadFailed = true
            self.notifySelectedScreen()
        }
    }

    private func notifySelectedScreen() {
        (selectedViewController as? ReusableMapScreenViewController)?.mapStateDidChange()
    }

    /// Reparents the shared map's WebView into `container`. The view is first
    /// detached from any previous superview so it can be safely re-attached.
    func attachMap(to container: UIView) {
        let mapWebView = mapView.view
        mapWebView.removeFromSuperview()
        mapWebView.translatesAutoresizingMaskIntoConstraints = false
        // Insert at the bottom of the z-order so any overlay (e.g. the loading
        // indicator) already in the container stays visible on top.
        container.insertSubview(mapWebView, at: 0)
        NSLayoutConstraint.activate([
            mapWebView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mapWebView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mapWebView.topAnchor.constraint(equalTo: container.topAnchor),
            mapWebView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    /// Focuses the shared map on the space chosen for the given screen index.
    func focus(forScreen index: Int) {
        guard isMapReady, let target = targetSpace(for: index) else { return }
        mapView.camera.focusOn(space: target)
    }

    /// The name of the space a screen focuses on, or nil if not loaded yet.
    func focusTargetName(for index: Int) -> String? {
        targetSpace(for: index)?.name
    }

    private func targetSpace(for index: Int) -> Space? {
        guard !spaces.isEmpty else { return nil }
        switch index {
        case 0: return spaces.first
        case 1: return spaces[spaces.count / 2]
        default: return spaces.last
        }
    }

    deinit {
        // Tear down the shared map only when the whole demo is finished.
        mapView.destroy()
    }
}
