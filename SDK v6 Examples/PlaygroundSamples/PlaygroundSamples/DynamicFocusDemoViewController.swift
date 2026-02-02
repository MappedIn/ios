import UIKit
import Mappedin

/// Demonstrates the Dynamic Focus extension for automatic outdoor/indoor scene management.
///
/// This demo uses the DynamicFocus extension directly with autoFocus enabled.
/// Zoom in and move the map around to observe Dynamic Focus auto focus behaviour.
final class DynamicFocusDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let stateLabel = UILabel()
    private let eventLogLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dynamic Focus"
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

        // Event log label to display DynamicFocus events
        eventLogLabel.text = "Events: --"
        eventLogLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        eventLogLabel.textColor = .systemBlue
        eventLogLabel.textAlignment = .left
        eventLogLabel.numberOfLines = 3
        eventLogLabel.translatesAutoresizingMaskIntoConstraints = false

        // Enable/Disable buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let enableButton = createButton(title: "Enable", action: #selector(enableDynamicFocus))
        let disableButton = createButton(title: "Disable", action: #selector(disableDynamicFocus))

        buttonStack.addArrangedSubview(enableButton)
        buttonStack.addArrangedSubview(disableButton)

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
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Map Loading

    private func loadMap() {
        // Trial API key - see https://developer.mappedin.com/docs/demo-keys-and-maps
        // Using the outdoor/indoor map for Dynamic Focus demo
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "682e13a2703478000b567b66"
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
            self?.statusLabel.text = "Map loaded - tap Enable to start Dynamic Focus"
        }

        // Label all spaces with names
        mapView.__EXPERIMENTAL__auto()
    }

    private func logEvent(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self?.eventLogLabel.text = "[\(timestamp)] \(message)"
        }
        print("[DynamicFocus Event] \(message)")
    }

    // MARK: - Actions

    @objc private func enableDynamicFocus() {
        let options = DynamicFocusOptions(
			autoFocus: true,
			indoorZoomThreshold: 17.0,
			outdoorZoomThreshold: 17.0,
            setFloorOnFocus: true,			
        )

        mapView.dynamicFocus.enable(options: options) { [weak self] result in
            guard let self = self else { return }
            if case .success = result {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Dynamic Focus enabled - zoom and pan to see auto focus"
                }
            }
            self.refreshStateDisplay()
        }
    }

    @objc private func disableDynamicFocus() {
        mapView.dynamicFocus.disable { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Dynamic Focus disabled"
            }
            self?.refreshStateDisplay()
        }
    }

    // MARK: - State Display

    private func refreshStateDisplay() {
        mapView.dynamicFocus.getState { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let state):
                    if let state = state {
                        let text = [
                            "autoFocus: \(state.autoFocus)",
                            "mode: \(state.mode.rawValue)"
                        ].joined(separator: " | ")
                        self?.stateLabel.text = text
                    } else {
                        self?.stateLabel.text = "State: not available"
                    }
                case .failure:
                    self?.stateLabel.text = "State: error"
                }
            }
        }
    }
}
