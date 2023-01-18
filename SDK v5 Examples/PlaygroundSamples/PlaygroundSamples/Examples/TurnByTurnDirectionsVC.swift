//
//  TurnByTurnDirectionsVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class TurnByTurnDirectionsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, MPIMapViewDelegate {
    let tableView = UITableView()
    let cellIdentifier: String = "instructionCell"
    var instructions: [MPIInstruction] = .init()
    var mapView: MPIMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView = MPIMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2))
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
        
        setupTableView()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: view.frame.height / 2).isActive = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instructions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel!.text = instructions[indexPath.row].instruction
        return cell
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        let departure = mapView?.venueData?.locations.first(where: { $0.name == "Pet World" })
        let destination = mapView?.venueData?.locations.first(where: { $0.name == "Microsoft" })

        guard departure != nil && destination != nil else { return }
        
        mapView?.getDirections(to: destination!, from: departure!) {
            directions in
            self.mapView?.journeyManager.draw(directions: directions!)
            self.instructions = directions?.instructions ?? [MPIInstruction]()
            self.tableView.reloadData()
        }
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
