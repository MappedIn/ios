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
    var loadingIndicator: UIActivityIndicatorView?
    
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
        
        loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
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
        } else {
            // No image for this location. clear out previous image.
            cell.logoImage.image = nil
        }
        cell.nameLabel.text = searchResults[indexPath.row].name
        cell.descLabel.text = searchResults[indexPath.row].description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let targetPolygons = searchResults[indexPath.row].polygons,
           let floor = targetPolygons.first?.map {
            // Ensure that the correct floor is displayed and map loaded before calling focusOn.
            if (floor.id != mapView?.currentMap?.id) {
                mapView?.setMap(map: floor) { (action) in
                    self.mapView?.cameraManager.focusOn(targets: MPIOptions.CameraTargets(polygons: targetPolygons))
                }
            }
            else {
                mapView?.cameraManager.focusOn(targets: MPIOptions.CameraTargets(polygons: targetPolygons))
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // This sample only shows locations of type tenant.
        // The filters below filter results that are MPIearchResultLocation (removing categories MPISearchResultCategory)
        // and where the location type is tenant (removing amenities $0.object.type = "amenities"). Location types can be unique
        // to each venue.  The list is then sorted, with the highest score first.
        mapView?.searchManager.search(query: searchText) {
            results in
            let searchLocations = results
                .compactMap { $0 as? MPISearchResultLocation }
                .filter({$0.object.type == "tenant"})
                .sorted(by: {$0.score > $1.score})
            
            self.searchResults.removeAll()
            
            searchLocations.forEach({ searchResultLocation in
                self.searchResults.append(searchResultLocation.object)
                // Print out the MPISearchMatch to logcat to show search match justification.
                print("Search Matches on: \(searchResultLocation.matches)")
            })
            self.tableView.reloadData()
        }
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {
        searchResults = mapView?.venueData?.locations ?? [MPILocation]()
        tableView.reloadData()
    }
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
