//
//  ListLocationsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class ListLocationsVC: UIViewController {
    let tableView = UITableView()
    var mapView: MPIMapView?

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
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension ListLocationsVC: UITableViewDataSource, UITableViewDelegate, MPIMapViewDelegate {
    func onDataLoaded(data: Mappedin.MPIData) {
        setupTableView()
    }
    
    func onFirstMapLoaded() {}
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mapView?.venueData?.locations.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.identifier, for: indexPath) as! LocationCell
        cell.nameLabel.text = mapView?.venueData?.locations[indexPath.row].name
        cell.descLabel.text = mapView?.venueData?.locations[indexPath.row].description
        return cell
    }
}

class LocationCell: UITableViewCell {
    public static let identifier = "LocationCell"
    let nameLabel = UILabel()
    let descLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        descLabel.font = .systemFont(ofSize: 18)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.frame = CGRect(x: 4, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height / 2)
        descLabel.frame = CGRect(x: 4, y: nameLabel.frame.size.height, width: contentView.frame.size.width, height: contentView.frame.size.height / 2)
    }
}
