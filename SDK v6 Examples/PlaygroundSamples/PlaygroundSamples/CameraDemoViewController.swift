import UIKit
import Mappedin

final class CameraDemoViewController: UIViewController {
    private let mapView = MapView()
    private var defaultPitch: Double?
    private var defaultZoomLevel: Double?
    private var defaultBearing: Double?
    private var defaultCenter: Coordinate?

    private let stackView = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Camera"
        view.backgroundColor = .systemBackground

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Setup controls stack view
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: stackView.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        setupButtons()

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(key: "mik_yeBk0Vf0nNJtpesfu560e07e5", secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022", mapId: "67881b4666a208000badecc4")
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                self.mapView.show3dMap(options: Show3DMapOptions()) { r2 in
                    if case .success = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        self.onMapReady()
                    } else if case .failure = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                    }
                }
            } else if case .failure(let error) = r {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                print("getMapData error: \(error)")
            }
        }
    }

    private func setupButtons() {
        // Pitch buttons
        let pitchStack = UIStackView()
        pitchStack.axis = .horizontal
        pitchStack.distribution = .fillEqually
        pitchStack.spacing = 8

        let increasePitchBtn = UIButton(type: .system)
        increasePitchBtn.setTitle("Increase Pitch", for: .normal)
        increasePitchBtn.addAction(UIAction { [weak self] _ in
            self?.increasePitch()
        }, for: .touchUpInside)
        pitchStack.addArrangedSubview(increasePitchBtn)

        let decreasePitchBtn = UIButton(type: .system)
        decreasePitchBtn.setTitle("Decrease Pitch", for: .normal)
        decreasePitchBtn.addAction(UIAction { [weak self] _ in
            self?.decreasePitch()
        }, for: .touchUpInside)
        pitchStack.addArrangedSubview(decreasePitchBtn)

        stackView.addArrangedSubview(pitchStack)

        // Zoom buttons
        let zoomStack = UIStackView()
        zoomStack.axis = .horizontal
        zoomStack.distribution = .fillEqually
        zoomStack.spacing = 8

        let zoomInBtn = UIButton(type: .system)
        zoomInBtn.setTitle("Zoom In", for: .normal)
        zoomInBtn.addAction(UIAction { [weak self] _ in
            self?.zoomIn()
        }, for: .touchUpInside)
        zoomStack.addArrangedSubview(zoomInBtn)

        let zoomOutBtn = UIButton(type: .system)
        zoomOutBtn.setTitle("Zoom Out", for: .normal)
        zoomOutBtn.addAction(UIAction { [weak self] _ in
            self?.zoomOut()
        }, for: .touchUpInside)
        zoomStack.addArrangedSubview(zoomOutBtn)

        stackView.addArrangedSubview(zoomStack)

        // Animate and Reset buttons
        let animateResetStack = UIStackView()
        animateResetStack.axis = .horizontal
        animateResetStack.distribution = .fillEqually
        animateResetStack.spacing = 8

        let animateBtn = UIButton(type: .system)
        animateBtn.setTitle("Animate", for: .normal)
        animateBtn.addAction(UIAction { [weak self] _ in
            self?.animate()
        }, for: .touchUpInside)
        animateResetStack.addArrangedSubview(animateBtn)

        let resetBtn = UIButton(type: .system)
        resetBtn.setTitle("Reset", for: .normal)
        resetBtn.addAction(UIAction { [weak self] _ in
            self?.reset()
        }, for: .touchUpInside)
        animateResetStack.addArrangedSubview(resetBtn)

        stackView.addArrangedSubview(animateResetStack)
    }

    private func increasePitch() {
        mapView.camera.pitch { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentPitch) = result {
                let newPitch = (currentPitch ?? 0.0) + 15.0
                let transform = CameraTarget(pitch: newPitch)
                self.mapView.camera.set(target: transform) { _ in }
            }
        }
    }

    private func decreasePitch() {
        mapView.camera.pitch { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentPitch) = result {
                let newPitch = (currentPitch ?? 0.0) - 15.0
                let transform = CameraTarget(pitch: newPitch)
                self.mapView.camera.set(target: transform) { _ in }
            }
        }
    }

    private func zoomIn() {
        mapView.camera.zoomLevel { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentZoom) = result {
                let newZoom = (currentZoom ?? 0.0) + 1.0
                let transform = CameraTarget(zoomLevel: newZoom)
                self.mapView.camera.set(target: transform) { _ in }
            }
        }
    }

    private func zoomOut() {
        mapView.camera.zoomLevel { [weak self] result in
            guard let self = self else { return }
            if case .success(let currentZoom) = result {
                let newZoom = (currentZoom ?? 0.0) - 1.0
                let transform = CameraTarget(zoomLevel: newZoom)
                self.mapView.camera.set(target: transform) { _ in }
            }
        }
    }

    private func animate() {
        mapView.camera.center { [weak self] result in
            guard let self = self else { return }
            if case .success(let center) = result, let center = center {
                let transform = CameraTarget(
                    bearing: 180.0,
                    center: center,
                    pitch: 60.0,
                    zoomLevel: 21.0
                )
                let options = CameraAnimationOptions(duration: 3000, easing: nil, interruptible: nil)
                self.mapView.camera.animateTo(target: transform, options: options) { _ in }
            }
        }
    }

	// Set the camera to the default position
    private func reset() {
        let transform = CameraTarget(
            bearing: defaultBearing,
            center: defaultCenter,
            pitch: defaultPitch,
            zoomLevel: defaultZoomLevel
        )
        mapView.camera.set(target: transform) { _ in }
    }

    private func onMapReady() {
        // Store default camera values
        mapView.camera.pitch { [weak self] result in
            if case .success(let pitch) = result {
                self?.defaultPitch = pitch
            }
        }
        mapView.camera.zoomLevel { [weak self] result in
            if case .success(let zoomLevel) = result {
                self?.defaultZoomLevel = zoomLevel
            }
        }
        mapView.camera.bearing { [weak self] result in
            if case .success(let bearing) = result {
                self?.defaultBearing = bearing
            }
        }
        mapView.camera.center { [weak self] result in
            if case .success(let center) = result {
                self?.defaultCenter = center
            }
        }

		// Focus the camera on the click location.
		mapView.on(Events.click) { [weak self] clickPayload in
			guard let self = self, let click = clickPayload else { return }
			self.mapView.camera.focusOn(coordinate: click.coordinate)
		}

		// Log camera change events to the console.
		mapView.on(Events.cameraChange) { [weak self] cameraTransform in
			guard self != nil, let transform = cameraTransform else { return }
			print("Camera changed to bearing: \(transform.bearing), pitch: \(transform.pitch), zoomLevel: \(transform.zoomLevel), center: Lat: \(transform.center.latitude), Lon: \(transform.center.longitude)")
		}

    }
}


