import UIKit
import Mappedin

// Simple wrapper to hold either a suggestion or a location
enum SearchListItem {
    case suggestion(Suggestion)
    case location(SearchResultEnterpriseLocations)
}

final class SearchDemoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let mapView = MapView()
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var searchResults: [SearchListItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        view.backgroundColor = .systemBackground

        setupUI()
        loadMap()
    }

    private func setupUI() {
        // Search bar
        searchBar.placeholder = "Search..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        // Table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        // Map view
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.33),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            container.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadMap() {
        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-mall"
        )
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    if case .success = r2 {
                        self.onMapReady()
                    } else if case .failure = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                    }
                }
            } else if case .failure(let error) = r {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                print("getMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        loadingIndicator.stopAnimating()

        // First, enable search
        mapView.mapData.search.enable { [weak self] result in
            guard let self = self else { return }
            if case .success = result {
                print("Search enabled")
                self.loadAllLocations()
            }
        }
    }

    private func loadAllLocations() {
        // Show all locations initially
        mapView.mapData.getByType(.enterpriseLocation) { [weak self] (result: Result<[EnterpriseLocation], Error>) in
            guard let self = self else { return }
            if case .success(let locations) = result {
                self.searchResults = locations.map { location in
                    SearchListItem.location(
                        SearchResultEnterpriseLocations(
                            item: location,
                            match: [:],
                            score: 0.0,
                            type: "enterprise-location"
                        )
                    )
                }
                self.tableView.reloadData()
            }
        }
    }

    // UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // Show all locations when search is cleared
            loadAllLocations()
        } else {
            // Get autocomplete suggestions
            mapView.mapData.search.suggest(term: searchText) { [weak self] result in
                guard let self = self else { return }
                if case .success(let suggestions) = result {
                    self.searchResults = suggestions?.map { SearchListItem.suggestion($0) } ?? []
                    self.tableView.reloadData()
                }
            }
        }
    }

    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = searchResults[indexPath.row]

        switch item {
        case .suggestion(let suggestion):
            let cell = UITableViewCell(style: .default, reuseIdentifier: "SuggestionCell")
            cell.textLabel?.text = suggestion.suggestion
            return cell

        case .location(let searchResult):
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "LocationCell")
            cell.textLabel?.text = searchResult.item.name
            cell.detailTextLabel?.text = searchResult.item.description
            return cell
        }
    }

    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = searchResults[indexPath.row]

        switch item {
        case .suggestion(let suggestion):
            // User selected a suggestion - search for locations matching this suggestion
            searchBar.text = suggestion.suggestion
            mapView.mapData.search.query(term: suggestion.suggestion) { [weak self] result in
                guard let self = self else { return }
                if case .success(let searchResult) = result {
                    self.searchResults = searchResult?.enterpriseLocations?
                        .sorted(by: { $0.score > $1.score })
                        .map { SearchListItem.location($0) } ?? []
                    self.tableView.reloadData()
                }
            }

        case .location(let searchResult):
            // User selected a location - focus on it
            let location = searchResult.item
            mapView.camera.focusOn(location: location) { [weak self] focusResult in
                guard let self = self else { return }
                if case .success = focusResult {
                    // Highlight all spaces for this location
                    location.spaces.forEach { spaceId in
                        self.mapView.mapData.getById(.space, id: spaceId) { (result: Result<Space?, Error>) in
                            if case .success(let space) = result, let space = space {
                                self.mapView.updateState(space: space, state: GeometryUpdateState(color: "#BF4320"))
                            }
                        }
                    }
                }
            }
        }
    }
}

