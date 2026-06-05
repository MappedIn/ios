import UIKit
import Mappedin

/// Enterprise Category Icons example.
///
/// Loads an Enterprise map, then adds a `Label` to every space of every enterprise location.
/// Each label uses the small icon associated with the location's first category (falling
/// back to an information icon) tinted to match the web example.
///
/// Unlike the other Icons examples (which only use the bridge), this example
/// renders a real map, so it owns its own visible `MapView`.
final class EnterpriseCategoryIconsViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    deinit {
        // Release the bridge WebView when leaving the Icons screen. In-flight
        // callbacks already bail via `[weak self]`, so nothing runs after this.
        mapView.destroy()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white

        let webview = mapView.view
        webview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webview)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            webview.topAnchor.constraint(equalTo: view.topAnchor),
            webview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webview.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        loadMap()
    }

    private func loadMap() {
        // See Demo API Key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-enterprise"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.mapView.show3dMap(options: Show3DMapOptions()) { [weak self] showResult in
                    guard let self else { return }
                    DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
                    switch showResult {
                    case .success:
                        self.addCategoryIconLabels()
                    case .failure(let error):
                        print("show3dMap error: \(error)")
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
                print("getMapData error: \(error)")
            }
        }
    }

    /// Builds a label for every space of every enterprise location, using the
    /// small icon of the location's first category.
    private func addCategoryIconLabels() {
        mapView.icons.initialize { _ in }

        loadCategoriesById { [weak self] categoriesById in
            self?.loadSpacesById { spacesById in
                self?.mapView.mapData.getByType(MapDataType.enterpriseLocation) { (result: Result<[EnterpriseLocation], Error>) in
                    switch result {
                    case .success(let locations):
                        for location in locations where !location.name.isEmpty {
                            self?.addLabels(for: location, categoriesById: categoriesById, spacesById: spacesById)
                        }
                    case .failure(let error):
                        print("getByType(enterpriseLocation) error: \(error)")
                    }
                }
            }
        }
    }

    private func addLabels(
        for location: EnterpriseLocation,
        categoriesById: [String: EnterpriseCategory],
        spacesById: [String: Space]
    ) {
        let category = location.categories.first.flatMap { categoriesById[$0] }
        let iconName = category?.iconFromDefaultList ?? "information"
        let color = category?.color ?? "black"

        mapView.icons.getByName(name: iconName) { [weak self] iconResult in
            let smallIconName: String
            switch iconResult {
            case .success(let icon):
                smallIconName = icon.smallIcon ?? "small-information-desk"
            case .failure:
                smallIconName = "small-information-desk"
            }

            self?.mapView.icons.fetchSvg(name: smallIconName) { svgResult in
                guard case .success(let svg) = svgResult else { return }
                let coloredSvg = svg.replacingOccurrences(of: "currentColor", with: "#fafafa")
                let appearance = LabelAppearance(color: color, icon: coloredSvg, iconPadding: 10)
                let labelOptions = AddLabelOptions(labelAppearance: appearance)

                for spaceId in location.spaces {
                    guard let space = spacesById[spaceId] else { continue }
                    self?.mapView.labels.add(target: space, text: location.name, options: labelOptions)
                }
            }
        }
    }

    private func loadCategoriesById(_ completion: @escaping ([String: EnterpriseCategory]) -> Void) {
        mapView.mapData.getByType(MapDataType.enterpriseCategory) { (result: Result<[EnterpriseCategory], Error>) in
            switch result {
            case .success(let categories):
                var byId: [String: EnterpriseCategory] = [:]
                for category in categories { byId[category.id] = category }
                completion(byId)
            case .failure(let error):
                print("getByType(enterpriseCategory) error: \(error)")
                completion([:])
            }
        }
    }

    private func loadSpacesById(_ completion: @escaping ([String: Space]) -> Void) {
        mapView.mapData.getByType(MapDataType.space) { (result: Result<[Space], Error>) in
            switch result {
            case .success(let spaces):
                var byId: [String: Space] = [:]
                for space in spaces { byId[space.id] = space }
                completion(byId)
            case .failure(let error):
                print("getByType(space) error: \(error)")
                completion([:])
            }
        }
    }
}
