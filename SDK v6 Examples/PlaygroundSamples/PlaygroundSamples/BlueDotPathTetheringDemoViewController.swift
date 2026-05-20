import UIKit
import Mappedin

/// Mirrors the Mappedin JS `Path_tethering` example. Demonstrates
/// `Navigation.trackCoordinate` (both tethered and travelled modes) driven by a pre-recorded
/// BlueDot walk through the `mappedin-demo-mall` venue. Supports Single Path
/// (entrance -> Aritzia) and Multi-Destination Path
/// (entrance -> Mucho Burrito -> Reebok -> Aritzia), with live controls for tether
/// threshold, outside-threshold style and mode, marker hiding, travelled color, active
/// destination, and full playback (play/pause + 1x/2x).
final class BlueDotPathTetheringDemoViewController: UIViewController {
    // Demo mall space IDs (north-east entrance + three stops).
    private static let startEntranceSpaceId = "s_6650b9a8cad393835892b92b"
    private static let muchoBurritoSpaceId = "s_62042759e325474a3000007b"
    private static let reebokSpaceId = "s_62042759e325474a30000079"
    private static let aritziaSpaceId = "s_62051551e325474a300010d5"
    private static let level2FloorName = "Level 2"

    private static let singlePositionsAsset = "tethering-demo-mall"
    private static let multiPositionsAsset = "tethering-demo-mall-multi-dest"

    private static let playbackIntervalMs: TimeInterval = 1.5

    private enum NavigationDemoMode { case none, single, multiDestination }
    private enum PathTrackingMode: Int { case tethered = 0, travelled = 1 }

    // MARK: - State
    private var trackingEnabled = true
    private var selectedDestination = 0
    private var tetherThreshold: Double = 5
    private var hideMarkersOutsideThreshold = false
    private var coordinateOutsideThresholdMode: CoordinateOutsideThresholdMode = .tetherAndDash
    private var outsideThresholdPathStyle: OutsideThresholdPathStyle = .dashedBoxes
    private var pathTrackingMode: PathTrackingMode = .tethered
    private var travelledColor = "#999999"
    private var navigationMode: NavigationDemoMode = .none

    // MARK: - Playback state
    private var currentPositions: [ManualPositionOptions] = []
    private var currentPositionIndex = 0
    private var isPaused = false
    private var playbackSpeed = 1
    private var playbackTimer: Timer?

    // MARK: - Cached directions
    private var singleDirections: Directions?
    private var multiDirections: [Directions]?

    // MARK: - Tracking state
    private var lastBlueDotPosition: Coordinate?

    // Floor ID → elevation lookup (populated after map data loads)
    private var floorIdToLevel: [String: Int] = [:]

    // MARK: - Views
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // Status panel
    private let statusContainer = UIStackView()
    private let isTrackingValue = UILabel()
    private let isShowingOutsideValue = UILabel()
    private let currentModeValue = UILabel()
    private let travelledFractionValue = UILabel()

    // Controls
    private let controlsContainer = UIStackView()
    private let initialControls = UIStackView()
    private let activeControls = UIStackView()
    private let trackingModeControl = UISegmentedControl(items: ["Tethered", "Travelled"])
    private let trackingEnabledSwitch = UISwitch()
    private let tetheredSettings = UIStackView()
    private let travelledSettings = UIStackView()
    private let destinationSettings = UIStackView()
    private let tetherSlider = UISlider()
    private let tetherValueLabel = UILabel()
    private let hideMarkersSwitch = UISwitch()
    private let outsideModeControl = UISegmentedControl(items: ["T+D", "Tether", "Untether"])
    private let outsideStyleControl = UISegmentedControl(items: ["Box", "Stripe", "Sparse", "Solid", "Border"])
    private let travelledColorField = UITextField()
    private let destinationControl = UISegmentedControl(items: ["Mucho", "Reebok", "Aritzia"])

    // Scrubber
    private let scrubberContainer = UIView()
    private let playPauseButton = UIButton(type: .system)
    private let speedButton = UIButton(type: .system)
    private let currentPositionLabel = UILabel()
    private let totalPositionsLabel = UILabel()
    private let positionSlider = UISlider()

    private let outsideModeOptions: [CoordinateOutsideThresholdMode] = [.tetherAndDash, .tetherOnly, .untether]
    private let outsideStyleOptions: [OutsideThresholdPathStyle] = [.dashedBoxes, .dashedStripes, .dashedSparse, .solid, .bordered]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Blue Dot Path Tethering"
        view.backgroundColor = .systemBackground

        buildLayout()
        showInitialControls()
        hideScrubber()
        loadMapData()
    }

    deinit {
        playbackTimer?.invalidate()
    }

    // MARK: - Layout

    private func buildLayout() {
        buildStatusPanel()
        buildControlsPanel()
        buildScrubber()

        let mapContainer = mapView.view
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapContainer)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        // Wrap status + controls in a scroll view so the full set of tethered
        // options fits on a mobile screen without crowding the map. The scroll
        // view is capped at ~33% of the available height; the map takes the rest.
        let topStack = UIStackView(arrangedSubviews: [statusContainer, controlsContainer])
        topStack.axis = .vertical
        topStack.spacing = 8
        topStack.translatesAutoresizingMaskIntoConstraints = false

        let topScroll = UIScrollView()
        topScroll.translatesAutoresizingMaskIntoConstraints = false
        topScroll.alwaysBounceVertical = true
        topScroll.addSubview(topStack)
        view.addSubview(topScroll)

        view.addSubview(scrubberContainer)
        scrubberContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topScroll.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.38),

            topStack.topAnchor.constraint(equalTo: topScroll.contentLayoutGuide.topAnchor, constant: 8),
            topStack.bottomAnchor.constraint(equalTo: topScroll.contentLayoutGuide.bottomAnchor, constant: -8),
            topStack.leadingAnchor.constraint(equalTo: topScroll.contentLayoutGuide.leadingAnchor, constant: 12),
            topStack.trailingAnchor.constraint(equalTo: topScroll.contentLayoutGuide.trailingAnchor, constant: -12),
            topStack.widthAnchor.constraint(equalTo: topScroll.frameLayoutGuide.widthAnchor, constant: -24),

            mapContainer.topAnchor.constraint(equalTo: topScroll.bottomAnchor),
            mapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainer.bottomAnchor.constraint(equalTo: scrubberContainer.topAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: mapContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: mapContainer.centerYAnchor),

            scrubberContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrubberContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrubberContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrubberContainer.heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    private func buildStatusPanel() {
        statusContainer.axis = .vertical
        statusContainer.spacing = 2

        let title = UILabel()
        title.text = "Navigation Tracking State"
        title.font = .boldSystemFont(ofSize: 11)
        title.textColor = .secondaryLabel
        statusContainer.addArrangedSubview(title)

        statusContainer.addArrangedSubview(makeStatusRow(label: "isTracking", value: isTrackingValue))
        statusContainer.addArrangedSubview(makeStatusRow(label: "isShowingOutsideThresholdPath", value: isShowingOutsideValue))
        statusContainer.addArrangedSubview(makeStatusRow(label: "currentTrackingMode", value: currentModeValue))
        statusContainer.addArrangedSubview(makeStatusRow(label: "travelledFraction", value: travelledFractionValue))

        hideTrackingStatusValues()
    }

    private func makeStatusRow(label text: String, value: UILabel) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        let labelView = UILabel()
        labelView.text = text
        labelView.font = UIFont(name: "Menlo", size: 11) ?? .systemFont(ofSize: 11)
        value.font = UIFont(name: "Menlo", size: 11) ?? .systemFont(ofSize: 11)
        value.text = "—"
        value.textAlignment = .right
        value.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(value)
        return row
    }

    private func buildControlsPanel() {
        controlsContainer.axis = .vertical
        controlsContainer.spacing = 6
        buildInitialControls()
        buildActiveControls()
        controlsContainer.addArrangedSubview(initialControls)
        controlsContainer.addArrangedSubview(activeControls)
    }

    private func buildInitialControls() {
        initialControls.axis = .vertical
        initialControls.spacing = 6

        let modeLabel = UILabel()
        modeLabel.text = "Tracking Mode"
        modeLabel.font = .systemFont(ofSize: 12)

        trackingModeControl.selectedSegmentIndex = 0
        trackingModeControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.pathTrackingMode = PathTrackingMode(rawValue: self.trackingModeControl.selectedSegmentIndex) ?? .tethered
        }, for: .valueChanged)

        let singleBtn = UIButton(type: .system)
        singleBtn.setTitle("Single Path", for: .normal)
        singleBtn.addAction(UIAction { [weak self] _ in self?.drawNavigation(mode: .single) }, for: .touchUpInside)

        let multiBtn = UIButton(type: .system)
        multiBtn.setTitle("Multi-Destination Path", for: .normal)
        multiBtn.addAction(UIAction { [weak self] _ in self?.drawNavigation(mode: .multiDestination) }, for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [singleBtn, multiBtn])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8

        initialControls.addArrangedSubview(modeLabel)
        initialControls.addArrangedSubview(trackingModeControl)
        initialControls.addArrangedSubview(buttonRow)
    }

    private func buildActiveControls() {
        activeControls.axis = .vertical
        activeControls.spacing = 6

        let enabledRow = UIStackView()
        enabledRow.axis = .horizontal
        enabledRow.spacing = 8
        let enabledLabel = UILabel()
        enabledLabel.text = "Tracking Enabled"
        enabledLabel.font = .systemFont(ofSize: 13)
        trackingEnabledSwitch.isOn = trackingEnabled
        trackingEnabledSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.trackingEnabled = self.trackingEnabledSwitch.isOn
            if !self.trackingEnabled {
                self.mapView.navigation.stopTracking { _ in self.refreshTrackingStatus() }
            } else {
                self.trackCurrentPosition()
            }
        }, for: .valueChanged)
        enabledRow.addArrangedSubview(enabledLabel)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        enabledRow.addArrangedSubview(spacer)
        enabledRow.addArrangedSubview(trackingEnabledSwitch)

        buildTetheredSettings()
        buildTravelledSettings()
        buildDestinationSettings()

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Clear Navigation", for: .normal)
        clearBtn.addAction(UIAction { [weak self] _ in self?.clearNavigation() }, for: .touchUpInside)

        activeControls.addArrangedSubview(enabledRow)
        activeControls.addArrangedSubview(tetheredSettings)
        activeControls.addArrangedSubview(travelledSettings)
        activeControls.addArrangedSubview(destinationSettings)
        activeControls.addArrangedSubview(clearBtn)
    }

    private func buildTetheredSettings() {
        tetheredSettings.axis = .vertical
        tetheredSettings.spacing = 4

        tetherValueLabel.text = "Tether Threshold: \(Int(tetherThreshold)) m"
        tetherValueLabel.font = .systemFont(ofSize: 12)

        tetherSlider.minimumValue = 1
        tetherSlider.maximumValue = 20
        tetherSlider.value = Float(tetherThreshold)
        tetherSlider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let v = max(1, Int(self.tetherSlider.value.rounded()))
            self.tetherThreshold = Double(v)
            self.tetherValueLabel.text = "Tether Threshold: \(v) m"
        }, for: .valueChanged)
        tetherSlider.addAction(UIAction { [weak self] _ in
            self?.trackCurrentPosition()
        }, for: [.touchUpInside, .touchUpOutside])

        let hideMarkersRow = UIStackView()
        hideMarkersRow.axis = .horizontal
        hideMarkersRow.spacing = 8
        let hideMarkersLabel = UILabel()
        hideMarkersLabel.text = "Hide Markers Outside Threshold"
        hideMarkersLabel.font = .systemFont(ofSize: 12)
        hideMarkersSwitch.isOn = hideMarkersOutsideThreshold
        hideMarkersSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.hideMarkersOutsideThreshold = self.hideMarkersSwitch.isOn
            self.trackCurrentPosition()
        }, for: .valueChanged)
        hideMarkersRow.addArrangedSubview(hideMarkersLabel)
        let hmSpacer = UIView()
        hmSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hideMarkersRow.addArrangedSubview(hmSpacer)
        hideMarkersRow.addArrangedSubview(hideMarkersSwitch)

        let outsideModeLabel = UILabel()
        outsideModeLabel.text = "Outside Threshold Mode"
        outsideModeLabel.font = .systemFont(ofSize: 12)
        outsideModeControl.selectedSegmentIndex = 0
        outsideModeControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let idx = self.outsideModeControl.selectedSegmentIndex
            self.coordinateOutsideThresholdMode = self.outsideModeOptions[idx]
            self.trackCurrentPosition()
        }, for: .valueChanged)

        let outsideStyleLabel = UILabel()
        outsideStyleLabel.text = "Outside Threshold Style"
        outsideStyleLabel.font = .systemFont(ofSize: 12)
        outsideStyleControl.selectedSegmentIndex = 0
        outsideStyleControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let idx = self.outsideStyleControl.selectedSegmentIndex
            self.outsideThresholdPathStyle = self.outsideStyleOptions[idx]
            self.trackCurrentPosition()
        }, for: .valueChanged)

        tetheredSettings.addArrangedSubview(tetherValueLabel)
        tetheredSettings.addArrangedSubview(tetherSlider)
        tetheredSettings.addArrangedSubview(hideMarkersRow)
        tetheredSettings.addArrangedSubview(outsideModeLabel)
        tetheredSettings.addArrangedSubview(outsideModeControl)
        tetheredSettings.addArrangedSubview(outsideStyleLabel)
        tetheredSettings.addArrangedSubview(outsideStyleControl)
    }

    private func buildTravelledSettings() {
        travelledSettings.axis = .vertical
        travelledSettings.spacing = 4

        let label = UILabel()
        label.text = "Travelled Color (hex)"
        label.font = .systemFont(ofSize: 12)

        travelledColorField.text = travelledColor
        travelledColorField.borderStyle = .roundedRect
        travelledColorField.autocapitalizationType = .none
        travelledColorField.autocorrectionType = .no
        travelledColorField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.commitTravelledColor()
        }, for: .editingDidEnd)

        travelledSettings.addArrangedSubview(label)
        travelledSettings.addArrangedSubview(travelledColorField)
    }

    private func buildDestinationSettings() {
        destinationSettings.axis = .vertical
        destinationSettings.spacing = 4

        let label = UILabel()
        label.text = "Active Destination"
        label.font = .systemFont(ofSize: 12)

        destinationControl.selectedSegmentIndex = 0
        destinationControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let idx = self.destinationControl.selectedSegmentIndex
            self.selectedDestination = idx
            self.mapView.navigation.setActivePathByIndex(target: idx) { _ in self.refreshTrackingStatus() }
        }, for: .valueChanged)

        destinationSettings.addArrangedSubview(label)
        destinationSettings.addArrangedSubview(destinationControl)
    }

    private func buildScrubber() {
        scrubberContainer.backgroundColor = UIColor.black.withAlphaComponent(0.85)

        playPauseButton.setTitle("❚❚", for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.isPaused.toggle()
            self.playPauseButton.setTitle(self.isPaused ? "▶" : "❚❚", for: .normal)
        }, for: .touchUpInside)

        speedButton.setTitle("1x", for: .normal)
        speedButton.tintColor = .white
        speedButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.playbackSpeed = self.playbackSpeed == 1 ? 2 : 1
            self.speedButton.setTitle("\(self.playbackSpeed)x", for: .normal)
            self.restartPlaybackTimer()
        }, for: .touchUpInside)

        currentPositionLabel.text = "0"
        currentPositionLabel.textColor = .white
        currentPositionLabel.font = .systemFont(ofSize: 13)
        totalPositionsLabel.text = "/ 0"
        totalPositionsLabel.textColor = .white
        totalPositionsLabel.font = .systemFont(ofSize: 13)

        positionSlider.minimumValue = 0
        positionSlider.maximumValue = 0
        positionSlider.value = 0
        positionSlider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let idx = Int(self.positionSlider.value.rounded())
            self.currentPositionIndex = idx
            self.currentPositionLabel.text = "\(idx)"
            if idx >= 0, idx < self.currentPositions.count {
                self.updatePosition(self.currentPositions[idx])
            }
        }, for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [
            playPauseButton, speedButton, currentPositionLabel, positionSlider, totalPositionsLabel,
        ])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        scrubberContainer.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: scrubberContainer.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: scrubberContainer.trailingAnchor, constant: -12),
            row.centerYAnchor.constraint(equalTo: scrubberContainer.centerYAnchor),
        ])
    }

    // MARK: - Map setup

    private func loadMapData() {
        // See Demo API Key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-mall"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.mapView.show3dMap(options: Show3DMapOptions()) { showResult in
                    DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
                    if case .success = showResult { self.onMapReady() }
                }
            case .failure(let error):
                DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
                print("BlueDotPathTethering: getMapData error: \(error)")
            }
        }
    }

    private func onMapReady() {
        mapView.mapData.getByType(.floor) { [weak self] (result: Result<[Floor], Error>) in
            guard let self else { return }
            if case .success(let floors) = result {
                for floor in floors {
                    self.floorIdToLevel[floor.id] = Int(floor.elevation)
                }
                if let level2 = floors.first(where: { $0.name == BlueDotPathTetheringDemoViewController.level2FloorName }) {
                    self.mapView.setFloor(floorId: level2.id) { _ in }
                }
            }
            self.preloadDirections()
            self.registerClickHandler()
            self.registerBlueDotPositionHandler()
        }
    }

    private func preloadDirections() {
        mapView.mapData.getById(.space, id: Self.startEntranceSpaceId) { [weak self] (startResult: Result<Space?, Error>) in
            guard let self, case .success(let start?) = startResult else { return }
            let startTarget: NavigationTarget = .space(start)

            self.mapView.mapData.getById(.space, id: Self.aritziaSpaceId) { [weak self] (aritziaResult: Result<Space?, Error>) in
                guard let self, case .success(let aritzia?) = aritziaResult else { return }
                self.mapView.mapData.getDirections(from: startTarget, to: .space(aritzia)) { [weak self] dResult in
                    if case .success(let directions?) = dResult {
                        self?.singleDirections = directions
                    }
                }
            }

            self.loadMultiDestinationDirections(startTarget: startTarget)
        }
    }

    private func loadMultiDestinationDirections(startTarget: NavigationTarget) {
        mapView.mapData.getById(.space, id: Self.muchoBurritoSpaceId) { [weak self] (muchoResult: Result<Space?, Error>) in
            guard let self, case .success(let mucho?) = muchoResult else { return }
            self.mapView.mapData.getById(.space, id: Self.reebokSpaceId) { [weak self] (reebokResult: Result<Space?, Error>) in
                guard let self, case .success(let reebok?) = reebokResult else { return }
                self.mapView.mapData.getById(.space, id: Self.aritziaSpaceId) { [weak self] (aritziaResult: Result<Space?, Error>) in
                    guard let self, case .success(let aritzia?) = aritziaResult else { return }
                    let destinations: [MultiDestinationTarget] = [
                        .single(.space(mucho)),
                        .single(.space(reebok)),
                        .single(.space(aritzia)),
                    ]
                    self.mapView.mapData.getDirectionsMultiDestination(from: startTarget, to: destinations) { [weak self] dResult in
                        if case .success(let dirs) = dResult {
                            self?.multiDirections = dirs
                        }
                    }
                }
            }
        }
    }

    private func registerClickHandler() {
        mapView.on(Events.click) { [weak self] (payload: ClickPayload?) in
            guard let self, let payload else { return }
            guard let floors = payload.floors, !floors.isEmpty else { return }
            let coord = payload.coordinate
            self.updatePosition(ManualPositionOptions(
                latitude: coord.latitude,
                longitude: coord.longitude,
                accuracy: 5,
                heading: 0,
                floorLevel: floors.first.map { Int($0.elevation) },
                confidence: 1.0
            ))
        }
    }

    private func registerBlueDotPositionHandler() {
        mapView.blueDot.on(BlueDotEvents.dotPositionUpdate) { [weak self] payload in
            guard let self, let payload else { return }
            self.lastBlueDotPosition = payload.position
            self.trackCurrentPosition()
        }
    }

    // MARK: - Navigation lifecycle

    private func drawNavigation(mode: NavigationDemoMode) {
        let pathOptions = AddPathOptions(
            accentColor: "white",
            animateArrowsOnPath: false,
            color: "#4b90e2",
            displayArrowsOnPath: false
        )
        let navOptions = NavigationOptions(pathOptions: pathOptions)

        let onDrawn: (Result<Any?, Error>) -> Void = { [weak self] _ in
            guard let self else { return }
            self.mapView.blueDot.enable(options: BlueDotOptions(radius: 5.0)) { [weak self] _ in
                guard let self else { return }
                self.mapView.blueDot.follow(
                    mode: .positionAndPathDirection,
                    cameraOptions: FollowCameraOptions(zoomLevel: 19.058859291133)
                ) { _ in }
                DispatchQueue.main.async {
                    self.showActiveControls()
                    self.refreshTrackingStatus()
                    self.startPositionPlayback(positions: self.loadPositions(for: mode))
                }
            }
        }

        switch mode {
        case .single:
            guard let directions = singleDirections else {
                print("BlueDotPathTethering: no directions available for mode=\(mode)")
                return
            }
            navigationMode = mode
            mapView.navigation.draw(directions: directions, options: navOptions, onResult: onDrawn)
        case .multiDestination:
            guard let directionsList = multiDirections, !directionsList.isEmpty else {
                print("BlueDotPathTethering: no directions available for mode=\(mode)")
                return
            }
            navigationMode = mode
            mapView.navigation.draw(directions: directionsList, options: navOptions, onResult: onDrawn)
        case .none:
            return
        }
    }

    private func clearNavigation() {
        mapView.navigation.clear { _ in }
        mapView.blueDot.disable { _ in }
        stopPositionPlayback()
        hideScrubber()
        hideTrackingStatusValues()
        navigationMode = .none
        showInitialControls()
    }

    private func trackCurrentPosition() {
        guard let pos = lastBlueDotPosition else { return }
        if navigationMode == .none || !trackingEnabled { return }

        let options: TrackCoordinateOptions
        switch pathTrackingMode {
        case .tethered:
            options = .tethered(TetheredOptions(
                tetherThresholdDistance: tetherThreshold,
                outsideThresholdPathStyle: outsideThresholdPathStyle,
                coordinateOutsideThresholdMode: coordinateOutsideThresholdMode,
                hideMarkersOutsideThreshold: hideMarkersOutsideThreshold
            ))
        case .travelled:
            options = .travelled(TravelledOptions(color: travelledColor))
        }

        mapView.navigation.trackCoordinate(coordinate: pos, options: options) { [weak self] _ in
            self?.refreshTrackingStatus()
        }
    }

    private func refreshTrackingStatus() {
        mapView.navigation.isTracking { [weak self] r in
            DispatchQueue.main.async {
                self?.isTrackingValue.text = String((try? r.get()) ?? false)
            }
        }
        mapView.navigation.isShowingOutsideThresholdPath { [weak self] r in
            DispatchQueue.main.async {
                self?.isShowingOutsideValue.text = String((try? r.get()) ?? false)
            }
        }
        mapView.navigation.currentTrackingMode { [weak self] r in
            DispatchQueue.main.async {
                let mode = (try? r.get()) ?? nil
                self?.currentModeValue.text = mode?.rawValue ?? "null"
            }
        }
        mapView.navigation.travelledFraction { [weak self] r in
            DispatchQueue.main.async {
                let frac = (try? r.get()) ?? nil
                self?.travelledFractionValue.text = frac.map { String(format: "%.1f%%", $0 * 100) } ?? "null"
            }
        }
    }

    private func hideTrackingStatusValues() {
        isTrackingValue.text = "—"
        isShowingOutsideValue.text = "—"
        currentModeValue.text = "—"
        travelledFractionValue.text = "—"
    }

    private func updatePosition(_ position: ManualPositionOptions) {
        mapView.blueDot.reportPosition(options: position) { _ in }
    }

    private func commitTravelledColor() {
        let candidate = (travelledColorField.text ?? "").trimmingCharacters(in: .whitespaces)
        let regex = try? NSRegularExpression(pattern: "^#[0-9a-fA-F]{6}$")
        if let regex,
           regex.firstMatch(in: candidate, range: NSRange(candidate.startIndex..., in: candidate)) != nil {
            travelledColor = candidate
            trackCurrentPosition()
        } else {
            travelledColorField.text = travelledColor
        }
    }

    // MARK: - Position playback

    private func loadPositions(for mode: NavigationDemoMode) -> [ManualPositionOptions] {
        let resource: String
        switch mode {
        case .single: resource = Self.singlePositionsAsset
        case .multiDestination: resource = Self.multiPositionsAsset
        case .none: return []
        }
        return parsePositionAsset(resource: resource)
    }

    private func parsePositionAsset(resource: String) -> [ManualPositionOptions] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("BlueDotPathTethering: failed to read \(resource).json")
            return []
        }
        var result: [ManualPositionOptions] = []
        result.reserveCapacity(array.count)
        for dict in array {
            guard let lat = dict["latitude"] as? Double,
                  let lon = dict["longitude"] as? Double else { continue }
            let floorId = dict["floorOrFloorId"] as? String
            result.append(ManualPositionOptions(
                latitude: lat,
                longitude: lon,
                accuracy: dict["accuracy"] as? Double,
                heading: dict["heading"] as? Double,
                floorLevel: floorId.flatMap { floorIdToLevel[$0] },
                confidence: 1.0
            ))
        }
        return result
    }

    private func startPositionPlayback(positions: [ManualPositionOptions]) {
        currentPositions = positions
        currentPositionIndex = 0
        isPaused = false
        playPauseButton.setTitle("❚❚", for: .normal)
        let lastIdx = max(positions.count - 1, 0)
        positionSlider.maximumValue = Float(lastIdx)
        positionSlider.value = 0
        currentPositionLabel.text = "0"
        totalPositionsLabel.text = "/ \(lastIdx)"
        showScrubber()
        restartPlaybackTimer()
    }

    private func restartPlaybackTimer() {
        playbackTimer?.invalidate()
        guard !currentPositions.isEmpty else { return }
        let interval = Self.playbackIntervalMs / Double(playbackSpeed)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.isPaused { return }
            if self.currentPositionIndex < self.currentPositions.count {
                self.updatePosition(self.currentPositions[self.currentPositionIndex])
                self.positionSlider.value = Float(self.currentPositionIndex)
                self.currentPositionLabel.text = "\(self.currentPositionIndex)"
                self.currentPositionIndex += 1
            } else {
                self.currentPositionIndex = 0
            }
        }
    }

    private func stopPositionPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func showScrubber() { scrubberContainer.isHidden = false }
    private func hideScrubber() { scrubberContainer.isHidden = true }

    // MARK: - Panel switching

    private func showInitialControls() {
        initialControls.isHidden = false
        activeControls.isHidden = true
    }

    private func showActiveControls() {
        initialControls.isHidden = true
        activeControls.isHidden = false
        tetheredSettings.isHidden = pathTrackingMode != .tethered
        travelledSettings.isHidden = pathTrackingMode != .travelled
        destinationSettings.isHidden = navigationMode != .multiDestination
        trackingEnabledSwitch.isOn = trackingEnabled
    }
}
