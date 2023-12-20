//
//  ViewController.swift
//  PlaygroundSamples
//

import UIKit

struct Example {
    var title: String
    var description: String
    var viewController: UIViewController
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    var examples: [Example] = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Mappedin Examples"
        setupTableView()
        setupExamples()
    }
    
    func setupExamples() {
        examples.append(Example(title: "Render a Map", description: "Basic venue loading and map rendering", viewController: RenderMapVC()))
        examples.append(Example(title: "Adding Interactivity", description: "React to touch events", viewController: AddingInteractivityVC()))
        examples.append(Example(title: "Markers", description: "Adding HTML markers to the map view", viewController: MarkersVC()))
        examples.append(Example(title: "A-B Wayfinding", description: "Get directions from A to B displayed on the map", viewController: ABWayfindingVC()))
        examples.append(Example(title: "Blue Dot", description: "Display the Blue Dot on the map", viewController: BlueDotVC()))
        examples.append(Example(title: "Camera Controls", description: "Set, animate or focus the camera on a set of map objects", viewController: CameraControlsVC()))
        examples.append(Example(title: "Floating Labels", description: "Display and modify floating labels", viewController: FloatingLabelsVC()))
        examples.append(Example(title: "Flat Labels", description: "Display and modify flat labels", viewController: FlatLabelsVC()))
        examples.append(Example(title: "List Locations", description: "List locations of a venue without rendering the map", viewController: ListLocationsVC()))
        examples.append(Example(title: "Tooltips", description: "Adding HTML tooltips to the map view", viewController: TooltipsVC()))
        examples.append(Example(title: "Building & Level Selection", description: "Add a building & level selector", viewController: LevelSelectorVC()))
        examples.append(Example(title: "Turn-by-Turn Directions", description: "Display text-based turn-by-turn directions", viewController: TurnByTurnDirectionsVC()))
        examples.append(Example(title: "Search", description: "Search locations within a venue", viewController: SearchVC()))
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
        tableView.register(ExampleCell.self, forCellReuseIdentifier: ExampleCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExampleCell.identifier, for: indexPath) as! ExampleCell
        cell.titleLabel.text = examples[indexPath.row].title
        cell.descLabel.text = examples[indexPath.row].description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = examples[indexPath.row].viewController
        vc.title = examples[indexPath.row].title
        navigationController?.pushViewController(examples[indexPath.row].viewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
