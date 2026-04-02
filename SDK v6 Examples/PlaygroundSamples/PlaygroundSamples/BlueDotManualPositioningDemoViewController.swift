import UIKit
import Mappedin

/// Demonstrates BlueDot manual positioning APIs including `forcePosition`,
/// `reportPosition`, and sensor management.
///
/// Manual positioning allows you to programmatically set or influence the
/// BlueDot position. This is useful for integrating external positioning
/// systems (IPS, beacons, WiFi RTT) or for scenarios like VPS calibration.
///
/// Key APIs demonstrated:
/// - `BlueDot.forcePosition` — Overrides all sensors with a fixed position for a duration
/// - `BlueDot.reportPosition` — Feeds a confidence-weighted position into the fusion engine
/// - `BlueDot.enableSensor` / `BlueDot.disableSensor` — Manages individual sensor sources
/// - `BlueDotEvents.anchorSet` / `BlueDotEvents.anchorExpired` — Anchor lifecycle events
final class BlueDotManualPositioningDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private var isManualSensorEnabled = false
    private var mapCenterLatitude: Double = 0.0
    private var mapCenterLongitude: Double = 0.0

    /// Button reference for toggling the manual sensor on and off.
    private var sensorToggleButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manual Positioning"
        view.backgroundColor = .systemBackground

        setupUI()
        loadMap()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Status label displays the most recent event or action result
        statusLabel.text = "Loading map..."
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Action buttons arranged in a vertical stack
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let forceButton = createButton(title: "Force Position", action: #selector(forcePositionTapped))
        let reportButton = createButton(title: "Report Position", action: #selector(reportPositionTapped))
        let toggleButton = createButton(title: "Enable Manual Sensor", action: #selector(toggleManualSensorTapped))
        sensorToggleButton = toggleButton

        // Top row: Force Position and Report Position side by side
        let topRow = UIStackView(arrangedSubviews: [forceButton, reportButton])
        topRow.axis = .horizontal
        topRow.distribution = .fillEqually
        topRow.spacing = 8

        buttonStack.addArrangedSubview(topRow)
        buttonStack.addArrangedSubview(toggleButton)

        // Map container
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        view.addSubview(statusLabel)
        view.addSubview(buttonStack)
        view.addSubview(container)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
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
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Map Loading

    private func loadMap() {
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
                    self.statusLabel.text = "Failed to load map"
                }
                print("getMapData error: \(error)")
            }
        }
    }

    /// Called once the 3D map has loaded successfully.
    /// Enables BlueDot and subscribes to anchor lifecycle events.
    private func onMapReady() {
        mapView.mapData.mapCenter { [weak self] result in
            if case .success(let center) = result, let center = center {
                self?.mapCenterLatitude = center.latitude
                self?.mapCenterLongitude = center.longitude
            }
        }

        enableBlueDot()
        subscribeToAnchorEvents()
    }

    // MARK: - BlueDot Setup

    /// Enables the BlueDot with manual positioning mode (no device position watching).
    private func enableBlueDot() {
        let options = BlueDotOptions(
            color: "#2266ff",
            heading: BlueDotOptions.Heading(color: "#2266ff", opacity: 0.6),
            radius: 12,
            watchDevicePosition: false
        )

        mapView.blueDot.enable(options: options) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if case .success = result {
                    self.statusLabel.text = "BlueDot enabled — use buttons to set position"
                } else {
                    self.statusLabel.text = "Failed to enable BlueDot"
                }
            }
        }
    }

    /// Subscribes to anchor lifecycle events to monitor when forced or reported
    /// positions are established and when they expire.
    private func subscribeToAnchorEvents() {
        mapView.blueDot.on(BlueDotEvents.anchorSet) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            let anchor = payload.anchor
            self.updateStatus(
                "Anchor set: sensor=\(anchor.sensorId) " +
                "(\(String(format: "%.4f", anchor.latitude)), " +
                "\(String(format: "%.4f", anchor.longitude))) " +
                "ttl=\(anchor.ttl)ms"
            )
        }

        mapView.blueDot.on(BlueDotEvents.anchorExpired) { [weak self] payload in
            guard let self = self, let payload = payload else { return }
            let anchor = payload.anchor
            self.updateStatus("Anchor expired: sensor=\(anchor.sensorId)")
        }
    }

    // MARK: - Actions

    /// Forces the BlueDot to a fixed position, overriding all other sensor data
    /// for the specified duration (30 seconds).
    @objc private func forcePositionTapped() {
        let position = BlueDot.ForcePositionTarget(
            latitude: mapCenterLatitude,
            longitude: mapCenterLongitude
        )

        mapView.blueDot.forcePosition(position: position, durationMs: 30000) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateStatus("Forced position for 30s at map center")
            case .failure(let error):
                self.updateStatus("forcePosition failed: \(error.localizedDescription)")
            }
        }
    }

    /// Reports a position to the fusion engine with a confidence weight.
    /// Unlike `forcePosition`, this does not override other sensors — the position
    /// is blended based on the confidence score.
    @objc private func reportPositionTapped() {
        let options = ManualPositionOptions(
            latitude: mapCenterLatitude,
            longitude: mapCenterLongitude,
            confidence: 0.8
        )

        mapView.blueDot.reportPosition(options: options) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateStatus("Reported position (confidence: 0.8)")
            case .failure(let error):
                self.updateStatus("reportPosition failed: \(error.localizedDescription)")
            }
        }
    }

    /// Toggles the "manual" sensor on or off. When enabled, the fusion engine
    /// accepts positions from `reportPosition`. When disabled, those reports
    /// are ignored.
    @objc private func toggleManualSensorTapped() {
        if isManualSensorEnabled {
            mapView.blueDot.disableSensor(sensorId: "manual") { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isManualSensorEnabled = false
                    DispatchQueue.main.async {
                        self.sensorToggleButton?.setTitle("Enable Manual Sensor", for: .normal)
                    }
                    self.updateStatus("Manual sensor disabled")
                case .failure(let error):
                    self.updateStatus("disableSensor failed: \(error.localizedDescription)")
                }
            }
        } else {
            mapView.blueDot.enableSensor(sensorId: "manual") { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let state):
                    self.isManualSensorEnabled = true
                    DispatchQueue.main.async {
                        self.sensorToggleButton?.setTitle("Disable Manual Sensor", for: .normal)
                    }
                    self.updateStatus("Manual sensor enabled (permission: \(state.rawValue))")
                case .failure(let error):
                    self.updateStatus("enableSensor failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helpers

    /// Updates the status label on the main thread and logs to the console.
    private func updateStatus(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let display = "[\(timestamp)] \(message)"
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = display
        }
        print("[ManualPositioning] \(message)")
    }
}
