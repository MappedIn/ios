//
//  ViewController.swift
//  MappedinDemoApp
//
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let demos = ["Areas & Shapes", "Blue Dot", "Building & Floor Selection", "Cache Map Data", "Cache MVF Data", "Camera", "Colors & Textures", "Display a Map", "Dynamic Focus", "Dynamic Focus (Manual)", "Image3D", "Interactivity", "Labels", "Locations", "Markers", "Models", "Multi-Floor View", "Navigation", "Offline Mode", "Paths", "Query", "Search", "Stacked Maps", "Text3D", "Turn by Turn"]

	private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mappedin SDK Samples"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { demos.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = demos[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            let vc = AreaShapesDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 1:
            let vc = BlueDotDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 2:
            let vc = BuildingFloorSelectionDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 3:
            let vc = CacheMapDataDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 4:
            let vc = CacheMVFDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 5:
            let vc = CameraDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 6:
            let vc = ColorsAndTexturesDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 7:
            let vc = DisplayMapDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 8:
            let vc = DynamicFocusDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 9:
            let vc = DynamicFocusManualDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 10:
            let vc = Image3DDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 11:
            let vc = InteractivityDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 12:
            let vc = LabelsDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 13:
            let vc = LocationsDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 14:
            let vc = MarkersDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 15:
            let vc = ModelsDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 16:
            let vc = MultiFloorViewDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 17:
            let vc = NavigationDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 18:
            let vc = OfflineModeDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 19:
            let vc = PathsDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 20:
            let vc = QueryDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 21:
            let vc = SearchDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 22:
            let vc = StackedMapsDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 23:
            let vc = Text3DDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        case 24:
            let vc = TurnByTurnDemoViewController()
            if let nav = navigationController { nav.pushViewController(vc, animated: true) }
            else { present(UINavigationController(rootViewController: vc), animated: true) }
        default:
            break
        }
    }
}

