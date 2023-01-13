//
//  ViewController.swift
//  PlaygroundSamples
//

import UIKit

class ViewController: UIViewController {
    private let tableView = UITableView()
    private var examples: [Example] = [Example]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        setupTableView()
        setupExamples()
    }

    func setupExamples() {
        examples.append(Example(title: "Render a Map", description: "Basic venue loading and map rendering", viewController: RenderMapVC())
        )
        examples.append(Example(title: "Adding Interactivity", description: "Make locations tappable", viewController: AddingInteractivityVC()))
        examples.append(Example(title: "Markers", description: "Adding HTML markers to the map view", viewController: MarkersVC()))
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.register(ExampleCell.self, forCellReuseIdentifier: ExampleCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
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
        navigationController?.pushViewController(examples[indexPath.row].viewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
}
