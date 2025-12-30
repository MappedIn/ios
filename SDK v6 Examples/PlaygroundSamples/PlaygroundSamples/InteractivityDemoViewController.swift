import UIKit
import Mappedin

final class InteractivityDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interactivity"
        view.backgroundColor = .systemBackground

        // Header UI
        let headerContainer = UIStackView()
        headerContainer.axis = .vertical
        headerContainer.spacing = 6
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Interactivity"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Click on labels, spaces, and paths to see interactive features in action."
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.systemGray
        descriptionLabel.numberOfLines = 0

        headerContainer.addArrangedSubview(titleLabel)
        headerContainer.addArrangedSubview(descriptionLabel)

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false

        let root = UIStackView(arrangedSubviews: [headerContainer, container])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/api-keys/
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-mall"
        )

        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                print("getMapData success")
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    if case .success = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap success - Map displayed")
                        self.onMapReady()
                    } else if case .failure(let error) = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap error: \(error)")
                    }
                }
            } else if case .failure(let error) = r {
                print("getMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        // Set all spaces to be interactive so they can be clicked
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }
            if case .success(let spaces) = result {
                spaces.forEach { space in
                    self.mapView.updateState(space: space, state: GeometryUpdateState(interactive: true))
                }
            }
        }

        // Set up click listener
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self = self, let click = clickPayload else { return }
            self.handleClick(click)
        }

		// Add interactive labels to all spaces with names.
		self.mapView.mapData.getByType(.space) { (spacesResult: Result<[Space], Error>) in
			if case .success(let spaces) = spacesResult {
				spaces.forEach { space in
					guard !space.name.isEmpty else { return }
					self.mapView.labels.add(
						target: space,
						text: space.name,
						options: AddLabelOptions(interactive: true)
					)
				}
			}
		}

        // Draw an interactive navigation path from Microsoft to Apple
        mapView.mapData.getByType(.enterpriseLocation) { [weak self] (result: Result<[EnterpriseLocation], Error>) in
            guard let self = self else { return }
            if case .success(let locations) = result {
                let microsoft = locations.first(where: { $0.name == "Microsoft" })
                let apple = locations.first(where: { $0.name == "Apple" })

                if let microsoft = microsoft, let apple = apple {
                    self.mapView.mapData.getDirections(
                        from: .enterpriseLocation(microsoft),
                        to: .enterpriseLocation(apple)
                    ) { dirResult in
                        if case .success(let directions?) = dirResult {
                            let pathOptions = AddPathOptions(interactive: true)
                            let navOptions = NavigationOptions(pathOptions: pathOptions)
                            self.mapView.navigation.draw(directions: directions, options: navOptions) { _ in }
                        }
                    }
                }
            }
        }

        // Draw an interactive path from Uniqlo to Nespresso
        mapView.mapData.getByType(.enterpriseLocation) { [weak self] (result: Result<[EnterpriseLocation], Error>) in
            guard let self = self else { return }
            if case .success(let locations) = result {
                let uniqlo = locations.first(where: { $0.name == "Uniqlo" })
                let nespresso = locations.first(where: { $0.name == "Nespresso" })

                if let uniqlo = uniqlo, let nespresso = nespresso {
                    self.mapView.mapData.getDirections(
                        from: .enterpriseLocation(uniqlo),
                        to: .enterpriseLocation(nespresso)
                    ) { dirResult in
                        if case .success(let directions?) = dirResult {
                            let pathOptions = AddPathOptions(interactive: true)
                            self.mapView.paths.add(coordinates: directions.coordinates, options: pathOptions) { _ in }
                        }
                    }
                }
            }
        }
    }

    private func handleClick(_ clickPayload: ClickPayload) {
        var message = ""

        // Use the map name as the title (from floors)
        let title = clickPayload.floors?.first?.name ?? "Map Click"

        // If a label was clicked, add its text to the message
        if let labels = clickPayload.labels, !labels.isEmpty {
            message.append("Label Clicked: ")
            message.append(labels.first?.text ?? "")
            message.append("\n")
        }

        // If a space was clicked, add its location name to the message
        if let spaces = clickPayload.spaces, !spaces.isEmpty {
            message.append("Space clicked: ")
            message.append(spaces.first?.name ?? "")
            message.append("\n")
        }

        // If a path was clicked, add it to the message
        if let paths = clickPayload.paths, !paths.isEmpty {
            message.append("You clicked a path.\n")
        }

        // Add the coordinates clicked to the message
        message.append("Coordinate Clicked: \nLatitude: ")
        message.append(clickPayload.coordinate.latitude.description)
        message.append("\nLongitude: ")
        message.append(clickPayload.coordinate.longitude.description)

        showMessage(title: title, message: message)
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}


