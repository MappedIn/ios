import UIKit
import Mappedin

/// Demonstrates the BlueDot indoor positioning visualization.
final class BlueDotDemoViewController: UIViewController {
    private let mapView = MapView()
    private var currentHeading: Double = 0.0
    private var currentAccuracy: Double = 5.0
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let stateLabel = UILabel()
    private let eventLogLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Blue Dot"
        view.backgroundColor = .systemBackground

        setupUI()
        loadMap()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Status label
        statusLabel.text = "Loading map..."
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // State label for live getter values
        stateLabel.text = "State: --"
        stateLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        stateLabel.textColor = .secondaryLabel
        stateLabel.textAlignment = .left
        stateLabel.numberOfLines = 0
        stateLabel.translatesAutoresizingMaskIntoConstraints = false

        // Event log label to display BlueDot events
        eventLogLabel.text = "Events: --"
        eventLogLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        eventLogLabel.textColor = .systemBlue
        eventLogLabel.textAlignment = .left
        eventLogLabel.numberOfLines = 3
        eventLogLabel.translatesAutoresizingMaskIntoConstraints = false

        // Control buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let enableButton = createButton(title: "Enable", action: #selector(enableBlueDot))
        let disableButton = createButton(title: "Disable", action: #selector(disableBlueDot))

        buttonStack.addArrangedSubview(enableButton)
        buttonStack.addArrangedSubview(disableButton)

        // Color buttons
        let colorStack = UIStackView()
        colorStack.axis = .horizontal
        colorStack.distribution = .fillEqually
        colorStack.spacing = 8
        colorStack.translatesAutoresizingMaskIntoConstraints = false

        let blueButton = createColorButton(color: .systemBlue, hexColor: "#2266ff")
        let greenButton = createColorButton(color: .systemGreen, hexColor: "#22cc44")
        let purpleButton = createColorButton(color: .systemPurple, hexColor: "#9922cc")
        let orangeButton = createColorButton(color: .systemOrange, hexColor: "#ff8800")

        colorStack.addArrangedSubview(blueButton)
        colorStack.addArrangedSubview(greenButton)
        colorStack.addArrangedSubview(purpleButton)
        colorStack.addArrangedSubview(orangeButton)

        // Heading buttons
        let headingStack = UIStackView()
        headingStack.axis = .horizontal
        headingStack.distribution = .fillEqually
        headingStack.spacing = 8
        headingStack.translatesAutoresizingMaskIntoConstraints = false

        let heading0Button = createHeadingButton(title: "0°", heading: 0.0)
        let heading90Button = createHeadingButton(title: "90°", heading: 90.0)
        let heading180Button = createHeadingButton(title: "180°", heading: 180.0)
        let heading270Button = createHeadingButton(title: "270°", heading: 270.0)

        headingStack.addArrangedSubview(heading0Button)
        headingStack.addArrangedSubview(heading90Button)
        headingStack.addArrangedSubview(heading180Button)
        headingStack.addArrangedSubview(heading270Button)

        // Accuracy buttons
        let accuracyStack = UIStackView()
        accuracyStack.axis = .horizontal
        accuracyStack.distribution = .fillEqually
        accuracyStack.spacing = 8
        accuracyStack.translatesAutoresizingMaskIntoConstraints = false

        let accuracy5Button = createAccuracyButton(title: "5m", accuracy: 5.0)
        let accuracy10Button = createAccuracyButton(title: "10m", accuracy: 10.0)
        let accuracy25Button = createAccuracyButton(title: "25m", accuracy: 25.0)
        let accuracy50Button = createAccuracyButton(title: "50m", accuracy: 50.0)

        accuracyStack.addArrangedSubview(accuracy5Button)
        accuracyStack.addArrangedSubview(accuracy10Button)
        accuracyStack.addArrangedSubview(accuracy25Button)
        accuracyStack.addArrangedSubview(accuracy50Button)

        view.addSubview(headingStack)
        view.addSubview(accuracyStack)

        // Map container
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        view.addSubview(statusLabel)
        view.addSubview(stateLabel)
        view.addSubview(eventLogLabel)
        view.addSubview(buttonStack)
        view.addSubview(colorStack)
        view.addSubview(container)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            stateLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            stateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            eventLogLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 4),
            eventLogLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            eventLogLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: eventLogLabel.bottomAnchor, constant: 8),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 36),

            colorStack.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            colorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            colorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            colorStack.heightAnchor.constraint(equalToConstant: 36),

            headingStack.topAnchor.constraint(equalTo: colorStack.bottomAnchor, constant: 8),
            headingStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headingStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headingStack.heightAnchor.constraint(equalToConstant: 36),

            accuracyStack.topAnchor.constraint(equalTo: headingStack.bottomAnchor, constant: 8),
            accuracyStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            accuracyStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            accuracyStack.heightAnchor.constraint(equalToConstant: 36),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: accuracyStack.bottomAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func createColorButton(color: UIColor, hexColor: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.tag = hexColor.hashValue
        button.accessibilityLabel = hexColor
        button.addTarget(self, action: #selector(changeColor(_:)), for: .touchUpInside)
        return button
    }

    private func createHeadingButton(title: String, heading: Double) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.tag = Int(heading)
        button.addTarget(self, action: #selector(setHeading(_:)), for: .touchUpInside)
        return button
    }

    private func createAccuracyButton(title: String, accuracy: Double) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.tag = Int(accuracy)
        button.addTarget(self, action: #selector(setAccuracy(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Map Loading

    private func loadMap() {
        // Trial API key - see https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "64ef49e662fd90fe020bee61"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.mapView.show3dMap(options: Show3DMapOptions()) { mapResult in
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                    }
                    if case .success = mapResult {
                        self.onMapReady()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                print("getMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Map loaded - tap Enable to start"
        }
        setupClickHandler()
        setupBlueDotEventListeners()
    }

    private func setupClickHandler() {
        mapView.on(Events.click) { [weak self] clickPayload in
            guard let self = self, let click = clickPayload else { return }
            self.moveBlueDot(to: click.coordinate, floors: click.floors)
        }
    }

    /// Sets up event listeners for BlueDot events to demonstrate the on() API.
    private func setupBlueDotEventListeners() {
        // Listen for position updates
        mapView.blueDot.on(BlueDotEvents.positionUpdate) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            let floorName = payload.floor?.name ?? "nil"
            let heading = payload.heading.map { String(format: "%.0f°", $0) } ?? "nil"
            self.logEvent("position-update: (\(String(format: "%.4f", payload.coordinate.latitude)), \(String(format: "%.4f", payload.coordinate.longitude))) floor=\(floorName) heading=\(heading)")
        }

        // Listen for status changes
        mapView.blueDot.on(BlueDotEvents.statusChange) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            self.logEvent("status-change: \(payload.status.rawValue) (action: \(payload.action.rawValue))")
        }

        // Listen for follow state changes
        mapView.blueDot.on(BlueDotEvents.followChange) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            let mode = payload.mode?.rawValue ?? "none"
            self.logEvent("follow-change: following=\(payload.following) mode=\(mode)")
        }

        // Listen for BlueDot clicks
        mapView.blueDot.on(BlueDotEvents.click) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            self.logEvent("click: (\(String(format: "%.4f", payload.coordinate.latitude)), \(String(format: "%.4f", payload.coordinate.longitude)))")
        }

        // Listen for errors
        mapView.blueDot.on(BlueDotEvents.error) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            self.logEvent("error: [\(payload.code)] \(payload.message)")
        }
    }

    /// Logs an event to the event log label
    private func logEvent(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self?.eventLogLabel.text = "[\(timestamp)] \(message)"
        }
        print("[BlueDot Event] \(message)")
    }

    // MARK: - Actions

    @objc private func enableBlueDot() {
        let options = BlueDotOptions(
            accuracyRing: BlueDotOptions.AccuracyRing(color: "#2266ff", opacity: 0.25),
            color: "#2266ff",
            heading: BlueDotOptions.Heading(color: "#2266ff", opacity: 0.6),
            initialState: .inactive,
            radius: 12,
            watchDevicePosition: false
        )

        mapView.blueDot.enable(options: options) { [weak self] result in
            guard let self = self else { return }
            if case .success = result {
                DispatchQueue.main.async {
                    self.statusLabel.text = "BlueDot enabled - tap map to place"
                }
            }
            self.refreshStateDisplay()
        }
    }

    private func moveBlueDot(to coordinate: Coordinate, floors: [Floor]?) {
        var floorId: BlueDotPositionUpdate.FloorId?

        if let firstFloor = floors?.first {
            floorId = .id(firstFloor.id)
        } else if let coordFloorId = coordinate.floorId {
            floorId = .id(coordFloorId)
        }

        let position = BlueDotPositionUpdate(
            accuracy: .value(currentAccuracy),
            floorId: floorId,
            heading: .value(currentHeading),
            latitude: .value(coordinate.latitude),
            longitude: .value(coordinate.longitude)
        )

        mapView.blueDot.update(position: position, options: BlueDotUpdateOptions(animate: true)) { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "BlueDot placed"
            }
            self?.refreshStateDisplay()
        }
    }

    @objc private func disableBlueDot() {
        mapView.blueDot.disable { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "BlueDot disabled"
            }
            self?.refreshStateDisplay()
        }
    }

    @objc private func setHeading(_ sender: UIButton) {
        let heading = Double(sender.tag)
        currentHeading = heading

        mapView.blueDot.update(
            position: BlueDotPositionUpdate(heading: .value(heading)),
            options: BlueDotUpdateOptions(animate: true)
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Heading set to \(Int(heading))°"
            }
            self?.refreshStateDisplay()
        }
    }

    @objc private func setAccuracy(_ sender: UIButton) {
        let accuracy = Double(sender.tag)
        currentAccuracy = accuracy

        mapView.blueDot.update(
            position: BlueDotPositionUpdate(accuracy: .value(accuracy)),
            options: BlueDotUpdateOptions(animate: true)
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Accuracy set to \(Int(accuracy))m"
            }
            self?.refreshStateDisplay()
        }
    }

    @objc private func changeColor(_ sender: UIButton) {
        guard let hexColor = sender.accessibilityLabel else { return }

        let options = BlueDotOptions(
            accuracyRing: BlueDotOptions.AccuracyRing(color: hexColor, opacity: 0.25),
            color: hexColor,
            heading: BlueDotOptions.Heading(color: hexColor, opacity: 0.6)
        )

        mapView.blueDot.updateState(options: options) { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "BlueDot color changed to \(hexColor)"
            }
            self?.refreshStateDisplay()
        }
    }

    // MARK: - State Display

    /// Fetches all getter values and updates the state label
    private func refreshStateDisplay() {
        var stateInfo: [String: String] = [:]
        let group = DispatchGroup()

        group.enter()
        mapView.blueDot.getIsEnabled { result in
            if case .success(let enabled) = result {
                stateInfo["enabled"] = enabled ? "true" : "false"
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getStatus { result in
            if case .success(let status) = result {
                stateInfo["status"] = status.rawValue
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getIsFollowing { result in
            if case .success(let following) = result {
                stateInfo["following"] = following ? "true" : "false"
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getHeading { result in
            if case .success(let heading) = result {
                stateInfo["heading"] = heading.map { String(format: "%.1f", $0) } ?? "nil"
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getAccuracy { result in
            if case .success(let accuracy) = result {
                stateInfo["accuracy"] = accuracy.map { String(format: "%.1fm", $0) } ?? "nil"
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getCoordinate { result in
            if case .success(let coord) = result {
                if let coord = coord {
                    stateInfo["coord"] = String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
                } else {
                    stateInfo["coord"] = "nil"
                }
            }
            group.leave()
        }

        group.enter()
        mapView.blueDot.getFloor(mapData: mapView.mapData) { result in
            if case .success(let floor) = result {
                stateInfo["floor"] = floor?.name ?? "nil"
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            let text = [
                "enabled: \(stateInfo["enabled"] ?? "?")",
                "status: \(stateInfo["status"] ?? "?")",
                "following: \(stateInfo["following"] ?? "?")",
                "heading: \(stateInfo["heading"] ?? "?")",
                "accuracy: \(stateInfo["accuracy"] ?? "?")",
                "coord: \(stateInfo["coord"] ?? "?")",
                "floor: \(stateInfo["floor"] ?? "?")"
            ].joined(separator: " | ")
            self?.stateLabel.text = text
        }
    }
}
