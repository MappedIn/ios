//
//  ListLocationsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class ListLocationsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, MPIMapViewDelegate {

    let tableView = UITableView()
    var mapView: MPIMapView?
    var sortedLocations: [MPILocation] = .init()
    var loadingIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView = MPIMapView(frame: CGRectNull)
        mapView?.delegate = self
        if let mapView = mapView {
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
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mapView?.venueData?.locations.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.identifier, for: indexPath) as! LocationCell
        if let url = URL(string: (sortedLocations[indexPath.row].logo?.small) ?? "") {
            cell.logoImage.load(url: url)
        }
        cell.nameLabel.text = sortedLocations[indexPath.row].name
        cell.descLabel.text = sortedLocations[indexPath.row].description
        return cell
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {
        sortedLocations = mapView?.venueData?.locations.filter { $0.type == "tenant" && $0.description != nil && $0.logo?.small != nil } ?? .init()
        sortedLocations.sort { $0.name < $1.name }
        setupTableView()
    }
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
}
