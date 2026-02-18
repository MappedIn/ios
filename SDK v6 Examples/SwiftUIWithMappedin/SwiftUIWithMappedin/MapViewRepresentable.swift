import SwiftUI
import Mappedin

class MapModel: ObservableObject {
    let mapView = MapView()
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
}

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var model: MapModel

    func makeUIView(context: Context) -> UIView {
        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/api-keys/
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-mall"
        )

        model.mapView.getMapData(options: options) { result in
            if case .success = result {
                model.mapView.show3dMap(options: Show3DMapOptions()) { showResult in
                    if case .success = showResult {
                        onMapReady()
                    } else if case .failure(let error) = showResult {
                        print("show3dMap error: \(error)")
                    }
                }
            } else if case .failure(let error) = result {
                print("getMapData error: \(error)")
            }
        }

        return model.mapView.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func onMapReady() {
        let mapView = model.mapView

        // Make all spaces interactive
        mapView.mapData.getByType(.space) { (result: Result<[Space], Error>) in
            if case .success(let spaces) = result {
                spaces.forEach { space in
                    mapView.updateState(space: space, state: GeometryUpdateState(interactive: true))
                }
            }
        }

        // Add interactive labels to all named spaces
        mapView.mapData.getByType(.space) { (result: Result<[Space], Error>) in
            if case .success(let spaces) = result {
                spaces.forEach { space in
                    guard !space.name.isEmpty else { return }
                    mapView.labels.add(
                        target: space,
                        text: space.name,
                        options: AddLabelOptions(interactive: true)
                    )
                }
            }
        }

        // Draw an interactive navigation path from Microsoft to Apple
        mapView.mapData.getByType(.enterpriseLocation) { (result: Result<[EnterpriseLocation], Error>) in
            if case .success(let locations) = result {
                let microsoft = locations.first(where: { $0.name == "Microsoft" })
                let apple = locations.first(where: { $0.name == "Apple" })

                if let microsoft = microsoft, let apple = apple {
                    mapView.mapData.getDirections(
                        from: .enterpriseLocation(microsoft),
                        to: .enterpriseLocation(apple)
                    ) { dirResult in
                        if case .success(let directions?) = dirResult {
                            let pathOptions = AddPathOptions(interactive: true)
                            let navOptions = NavigationOptions(pathOptions: pathOptions)
                            mapView.navigation.draw(directions: directions, options: navOptions) { _ in }
                        }
                    }
                }
            }
        }

        // Draw an interactive path from Uniqlo to Nespresso
        mapView.mapData.getByType(.enterpriseLocation) { (result: Result<[EnterpriseLocation], Error>) in
            if case .success(let locations) = result {
                let uniqlo = locations.first(where: { $0.name == "Uniqlo" })
                let nespresso = locations.first(where: { $0.name == "Nespresso" })

                if let uniqlo = uniqlo, let nespresso = nespresso {
                    mapView.mapData.getDirections(
                        from: .enterpriseLocation(uniqlo),
                        to: .enterpriseLocation(nespresso)
                    ) { dirResult in
                        if case .success(let directions?) = dirResult {
                            let pathOptions = AddPathOptions(interactive: true)
                            mapView.paths.add(coordinates: directions.coordinates, options: pathOptions) { _ in }
                        }
                    }
                }
            }
        }

        // Listen for click events and publish to model for SwiftUI alert
        mapView.on(Events.click) { [model] clickPayload in
            guard let click = clickPayload else { return }
            DispatchQueue.main.async {
                model.alertTitle = click.floors?.first?.name ?? "Map Click"
                var message = ""

                if let labels = click.labels, !labels.isEmpty {
                    message.append("Label Clicked: \(labels.first?.text ?? "")\n")
                }

                if let spaces = click.spaces, !spaces.isEmpty {
                    message.append("Space Clicked: \(spaces.first?.name ?? "")\n")
                }

                if let paths = click.paths, !paths.isEmpty {
                    message.append("You clicked a path.\n")
                }

                message.append("Coordinate Clicked:\nLatitude: \(click.coordinate.latitude)\nLongitude: \(click.coordinate.longitude)")

                model.alertMessage = message
                model.showAlert = true
            }
        }
    }
}
