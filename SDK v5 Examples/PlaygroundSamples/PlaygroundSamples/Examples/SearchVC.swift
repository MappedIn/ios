//
//  SearchVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class SearchVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MPIMapViewDelegate {
    let searchStackView = UIStackView()
    let tableView = UITableView()
    let search = UISearchBar()
    var results: [MPILocation] = .init()
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView = MPIMapView(frame: CGRect(x: 0, y: view.frame.height / 4, width: view.frame.width, height: (view.frame.height / 4) * 3))
        mapView?.delegate = self
        if let mapView = mapView {
            view.addSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ))
        }
        setupSearchView()
    }
    
    func setupSearchView() {
        view.addSubview(searchStackView)
        searchStackView.axis = .vertical
        searchStackView.translatesAutoresizingMaskIntoConstraints = false
        searchStackView.heightAnchor.constraint(equalToConstant: view.frame.height / 4).isActive = true
        searchStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        searchStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        searchStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        search.placeholder = "Search..."
        search.delegate = self
        searchStackView.addArrangedSubview(search)
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        searchStackView.addArrangedSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.identifier, for: indexPath) as! LocationCell
        cell.nameLabel.text = results[indexPath.row].name
        cell.descLabel.text = results[indexPath.row].description
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        mapView?.searchManager.search(query: searchText) {
            searchResult in
            var filteredSearchResults: [MPILocation] = .init()
            let matches = searchResult.flatMap { $0.matches.filter { $0.matchesOn == "name" } }
            for match in matches {
                if let location = self.mapView?.venueData?.locations.first(where: { $0.name == match.value }) {
                    // Check for duplicates
                    guard !filteredSearchResults.contains(where: { $0.name == location.name }) else {
                        continue
                    }
                    filteredSearchResults.append(location)
                }
            }
            self.results = filteredSearchResults
            self.tableView.reloadData()
        }
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {
        results = mapView?.venueData?.locations ?? [MPILocation]()
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
