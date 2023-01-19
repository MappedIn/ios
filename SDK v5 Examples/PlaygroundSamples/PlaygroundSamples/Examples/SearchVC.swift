//
//  SearchVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class SearchVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MPIMapViewDelegate {
    let mainStackView = UIStackView()
    let searchStackView = UIStackView()
    let tableView = UITableView()
    let searchBar = UISearchBar()
    var searchResults: [MPILocation] = .init()
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMainStackView()
        setupSearchView()
        setupMapView()
    }
    
    func setupMainStackView() {
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.alignment = .fill
    }
    
    func setupMapView() {
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
        if let mapView = mapView {
            mainStackView.addArrangedSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ))
        }
    }
    
    func setupSearchView() {
        mainStackView.addArrangedSubview(searchStackView)
        searchStackView.axis = .vertical
        searchStackView.heightAnchor.constraint(equalToConstant: view.frame.height / 3).isActive = true

        searchBar.placeholder = "Search..."
        searchBar.delegate = self
        searchStackView.addArrangedSubview(searchBar)
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        searchStackView.addArrangedSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.identifier, for: indexPath) as! LocationCell
        if let url = URL(string: (searchResults[indexPath.row].logo?.small) ?? "") {
            cell.logoImage.load(url: url)
        }
        cell.nameLabel.text = searchResults[indexPath.row].name
        cell.descLabel.text = searchResults[indexPath.row].description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mapView?.cameraManager.focusOn(targets: MPIOptions.CameraTargets(polygons: searchResults[indexPath.row].polygons))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        mapView?.searchManager.search(query: searchText) {
            results in
            var filteredSearchResults: [MPILocation] = .init()
            let matches = results.flatMap { $0.matches.filter { $0.matchesOn == "name" } }
            for match in matches {
                if let location = self.mapView?.venueData?.locations.first(where: { $0.name == match.value }) {
                    // Check for duplicates
                    guard !filteredSearchResults.contains(where: { $0.name == location.name }) else {
                        continue
                    }
                    filteredSearchResults.append(location)
                }
            }
            self.searchResults = filteredSearchResults
            self.tableView.reloadData()
        }
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {
        searchResults = mapView?.venueData?.locations ?? [MPILocation]()
        tableView.reloadData()
    }
    
    func onFirstMapLoaded() {}
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
