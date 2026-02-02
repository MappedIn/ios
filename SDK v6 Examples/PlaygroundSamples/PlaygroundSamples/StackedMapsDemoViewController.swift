import UIKit
import Mappedin

final class StackedMapsDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var animate = true
    private var distanceBetweenFloors: Double = 25.0
    private var gapValueLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stacked Maps"
        view.backgroundColor = .systemBackground

        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Add loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        // Add control panel
        let controlPanel = createControlPanel()
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlPanel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            controlPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            controlPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

		// See Trial API key Terms and Conditions
		// https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "666ca6a48dd908000bf47803"
        )

		// Load the map data.
        mapView.getMapData(options: options) { [weak self] r in
            guard let self = self else { return }
            if case .success = r {
                print("getMapData success")

				// Display the map with higher pitch for better stacked view.
                let show3dMapOptions = Show3DMapOptions(
                    pitch: 80.0
                )

                self.mapView.show3dMap(options: show3dMapOptions) { r2 in
                    if case .success = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
						self.onMapReady()
                    } else if case .failure(let error) = r2 {
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                        }
                        print("show3dMap error: \(error)")
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

    private func createControlPanel() -> UIView {
        let panel = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        panel.layer.cornerRadius = 12
        panel.clipsToBounds = true

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: panel.contentView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: panel.contentView.bottomAnchor, constant: -16),
        ])

        // Expand button
        let expandButton = UIButton(type: .system)
        expandButton.setTitle("Expand", for: .normal)
        expandButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        expandButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
        stackView.addArrangedSubview(expandButton)

        // Collapse button
        let collapseButton = UIButton(type: .system)
        collapseButton.setTitle("Collapse", for: .normal)
        collapseButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        collapseButton.addTarget(self, action: #selector(collapseTapped), for: .touchUpInside)
        stackView.addArrangedSubview(collapseButton)

        // Animate toggle
        let animateStack = UIStackView()
        animateStack.axis = .horizontal
        animateStack.spacing = 8

        let animateLabel = UILabel()
        animateLabel.text = "Animate"
        animateLabel.font = UIFont.systemFont(ofSize: 14)

        let animateSwitch = UISwitch()
        animateSwitch.isOn = animate
        animateSwitch.addTarget(self, action: #selector(animateToggled(_:)), for: .valueChanged)

        animateStack.addArrangedSubview(animateLabel)
        animateStack.addArrangedSubview(animateSwitch)
        stackView.addArrangedSubview(animateStack)

        // Floor gap label
        let floorGapLabel = UILabel()
        floorGapLabel.text = "Floor Gap:"
        floorGapLabel.font = UIFont.systemFont(ofSize: 14)
        stackView.addArrangedSubview(floorGapLabel)

        // Floor gap slider
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 50
        slider.value = Float(distanceBetweenFloors)
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        stackView.addArrangedSubview(slider)

        // Gap value display
        gapValueLabel = UILabel()
        gapValueLabel.text = "\(Int(distanceBetweenFloors))m"
        gapValueLabel.font = UIFont.systemFont(ofSize: 14)
        gapValueLabel.textAlignment = .center
        stackView.addArrangedSubview(gapValueLabel)

        return panel
    }

    @objc private func expandTapped() {
        StackedMapsUtils.expandFloors(
            mapView: mapView,
            options: ExpandOptions(
                distanceBetweenFloors: distanceBetweenFloors,
                animate: animate
            )
        )
    }

    @objc private func collapseTapped() {
        StackedMapsUtils.collapseFloors(
            mapView: mapView,
            options: CollapseOptions(animate: animate)
        )
    }

    @objc private func animateToggled(_ sender: UISwitch) {
        animate = sender.isOn
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        distanceBetweenFloors = Double(sender.value)
        gapValueLabel.text = "\(Int(distanceBetweenFloors))m"

        // Automatically expand floors with new gap value
        StackedMapsUtils.expandFloors(
            mapView: mapView,
            options: ExpandOptions(
                distanceBetweenFloors: distanceBetweenFloors,
                animate: animate
            )
        )
    }

	// Place your code to be called when the map is ready here.
	private func onMapReady() {
		print("show3dMap success - Map displayed")

		// Hide the outdoor map and configure camera for stacked view.
		mapView.outdoor.hide()
		mapView.camera.setMaxPitch(88.0)
		mapView.camera.set(
			target: CameraTarget(pitch: 75.0)
		)

		//Expland floors.
		StackedMapsUtils.expandFloors(
			mapView: mapView,
			options: ExpandOptions(
				distanceBetweenFloors: distanceBetweenFloors,
				animate: animate
			)
		)
	}
}

