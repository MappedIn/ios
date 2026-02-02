import UIKit
import Mappedin

/// Demonstrates manual Dynamic Focus-like behaviour using MapView methods.
///
/// This demo implements similar effects to DynamicFocus but using direct MapView
/// state updates for more custom control over facade/floor visibility.
final class DynamicFocusManualDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let eventLogLabel = UILabel()
    private let buildingPicker = UIPickerView()
    private let floorPicker = UIPickerView()

    private let animationDuration = 150
    private var floorToShowByBuilding: [String: Floor] = [:]
    private var currentElevation: Double = 0.0

    // Cached data
    private var allFloorStacks: [FloorStack] = []
    private var allFloors: [Floor] = []
    private var allFacades: [Facade] = []
    private var currentFloorStackFloors: [Floor] = []

    // Track the currently selected building (nil = outdoor/no building selected)
    private var currentSelectedFloorStackId: String?

    // Flag to prevent picker delegate from firing during programmatic updates
    private var isUpdatingPickers = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dynamic Focus (Manual)"
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

        // Event log label
        eventLogLabel.text = "Events: --"
        eventLogLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        eventLogLabel.textColor = .systemBlue
        eventLogLabel.textAlignment = .left
        eventLogLabel.numberOfLines = 3
        eventLogLabel.translatesAutoresizingMaskIntoConstraints = false

        // Picker labels
        let buildingLabel = UILabel()
        buildingLabel.text = "Building:"
        buildingLabel.font = .systemFont(ofSize: 14)
        buildingLabel.textColor = .label
        buildingLabel.translatesAutoresizingMaskIntoConstraints = false

        let floorLabel = UILabel()
        floorLabel.text = "Floor:"
        floorLabel.font = .systemFont(ofSize: 14)
        floorLabel.textColor = .label
        floorLabel.translatesAutoresizingMaskIntoConstraints = false

        // Building picker
        buildingPicker.delegate = self
        buildingPicker.dataSource = self
        buildingPicker.translatesAutoresizingMaskIntoConstraints = false
        buildingPicker.tag = 0

        // Floor picker
        floorPicker.delegate = self
        floorPicker.dataSource = self
        floorPicker.translatesAutoresizingMaskIntoConstraints = false
        floorPicker.tag = 1

        // Picker container
        let pickerStack = UIStackView()
        pickerStack.axis = .horizontal
        pickerStack.distribution = .fillEqually
        pickerStack.spacing = 8
        pickerStack.translatesAutoresizingMaskIntoConstraints = false

        let buildingStack = UIStackView(arrangedSubviews: [buildingLabel, buildingPicker])
        buildingStack.axis = .vertical
        buildingStack.spacing = 4

        let floorStack = UIStackView(arrangedSubviews: [floorLabel, floorPicker])
        floorStack.axis = .vertical
        floorStack.spacing = 4

        pickerStack.addArrangedSubview(buildingStack)
        pickerStack.addArrangedSubview(floorStack)

        // Map container
        let container = mapView.view
        container.translatesAutoresizingMaskIntoConstraints = false

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        view.addSubview(statusLabel)
        view.addSubview(eventLogLabel)
        view.addSubview(pickerStack)
        view.addSubview(container)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            eventLogLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            eventLogLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            eventLogLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            pickerStack.topAnchor.constraint(equalTo: eventLogLabel.bottomAnchor, constant: 8),
            pickerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pickerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pickerStack.heightAnchor.constraint(equalToConstant: 100),

            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: pickerStack.bottomAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Map Loading

    private func loadMap() {
        // Trial API key - see https://developer.mappedin.com/docs/demo-keys-and-maps
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
            self?.statusLabel.text = "Manual floor visibility control active"
        }

        // Label all spaces with names
        mapView.mapData.getByType(.space) { [weak self] (result: Result<[Space], Error>) in
            guard let self = self else { return }
            if case .success(let spaces) = result {
                spaces.forEach { space in
                    if !space.name.isEmpty {
                        self.mapView.labels.add(target: space, text: space.name)
                    }
                }
            }
        }

        // Fetch all floor stacks
        mapView.mapData.getByType(.floorStack) { [weak self] (result: Result<[FloorStack], Error>) in
            guard let self = self else { return }
            if case .success(let stacks) = result {
                self.allFloorStacks = stacks.sorted { $0.name < $1.name }

                // Fetch all floors
                self.mapView.mapData.getByType(.floor) { [weak self] (result: Result<[Floor], Error>) in
                    guard let self = self else { return }
                    if case .success(let floors) = result {
                        self.allFloors = floors

                        // Fetch all facades
                        self.mapView.mapData.getByType(.facade) { [weak self] (result: Result<[Facade], Error>) in
                            guard let self = self else { return }
                            if case .success(let facades) = result {
                                self.allFacades = facades
                                print("[DynamicFocusManual] Loaded \(facades.count) facades")

                                DispatchQueue.main.async {
                                    self.populateFloorStacks()
                                    self.updateFloorsToShow()
                                    self.setupEventListeners()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Building/Floor Management

    /// Get the facade for a floor stack, if it has one
    private func getFacadeForFloorStack(_ floorStackId: String) -> Facade? {
        return allFacades.first { $0.floorStack == floorStackId }
    }

    /// Get a Floor object by its ID
    private func getFloorById(_ floorId: String) -> Floor? {
        return allFloors.first { $0.id == floorId }
    }

    /// Get floors for a floor stack as Floor objects
    private func getFloorsForFloorStack(_ floorStack: FloorStack) -> [Floor] {
        return floorStack.floors.compactMap { floorId in
            allFloors.first { $0.id == floorId }
        }
    }

    /// Switch to viewing a building by manually managing facades and floors.
    /// This does NOT call setFloorStack or setFloor for buildings - instead it manages
    /// visibility of floors and facades directly while staying on the outdoor floor.
    /// This allows facades to remain rendered while showing building interiors.
    /// - Parameter focusCamera: Whether to focus the camera on the target. Set to false when
    ///   switching due to panning (facades-in-view-change with 0 facades) to avoid snapping back.
    private func switchToBuilding(_ floorStack: FloorStack, focusCamera: Bool = true) {
        currentSelectedFloorStackId = floorStack.id

        print("[DynamicFocusManual] switchToBuilding: \(floorStack.name) (\(floorStack.id)) focusCamera=\(focusCamera)")

        // Check if this is an Outdoor-type floor stack
        let isOutdoor = floorStack.type == .outdoor

        if isOutdoor {
            // Switching to Outdoor - close all facades (show them) and hide all building floors
            print("[DynamicFocusManual]   Switching to Outdoor view")

            // Close all facades (make them visible)
            allFacades.forEach { facade in
                closeFacade(facade)
            }

            // Set floor to the outdoor floor
            let defaultFloorId = floorStack.defaultFloor
            if let floor = getFloorById(defaultFloorId) {
                mapView.setFloor(floorId: defaultFloorId)
                // Only focus if explicitly requested (e.g., from picker selection)
                if focusCamera {
                    mapView.camera.focusOn(floor: floor)
                }
            }
        } else {
            // Switching to a Building - open its facade (hide it) and show its floors
            print("[DynamicFocusManual]   Switching to Building: \(floorStack.name)")

            // Process all facades
            allFacades.forEach { facade in
                if facade.floorStack == floorStack.id {
                    // Open this building's facade (hide it to reveal interior)
                    openFacade(facade)
                } else {
                    // Close other building facades (show them)
                    closeFacade(facade)
                }
            }

            // Populate floors for this building's floor selector
            populateFloors(floorStackId: floorStack.id)

            // Focus on the default floor WITHOUT calling setFloor
            // This keeps the outdoor floor as the "current floor" so facades remain rendered
            // Only focus if explicitly requested (e.g., from picker selection)
            if focusCamera {
                let defaultFloorId = floorStack.defaultFloor
                if let floor = getFloorById(defaultFloorId) {
                    // Just focus the camera on the building's floor, don't change current floor
                    mapView.camera.focusOn(floor: floor)
                }
            }
        }
    }

    private func populateFloorStacks() {
        isUpdatingPickers = true
        buildingPicker.reloadAllComponents()

        // Set initial building
        mapView.currentFloorStack { [weak self] (result: Result<FloorStack?, Error>) in
            guard let self = self else { return }
            if case .success(let currentFloorStack) = result, let currentFloorStack = currentFloorStack {
                if let index = self.allFloorStacks.firstIndex(where: { $0.id == currentFloorStack.id }) {
                    DispatchQueue.main.async {
                        self.buildingPicker.selectRow(index, inComponent: 0, animated: false)
                        self.isUpdatingPickers = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isUpdatingPickers = false
                    }
                }
                self.currentSelectedFloorStackId = currentFloorStack.id
                self.populateFloors(floorStackId: currentFloorStack.id)
            } else {
                DispatchQueue.main.async {
                    self.isUpdatingPickers = false
                }
            }
        }
    }

    private func populateFloors(floorStackId: String) {
        guard let floorStack = allFloorStacks.first(where: { $0.id == floorStackId }) else { return }

        // Get Floor objects for all floor IDs in this floor stack
        currentFloorStackFloors = getFloorsForFloorStack(floorStack).sorted { $0.elevation > $1.elevation }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.isUpdatingPickers = true
            self.floorPicker.reloadAllComponents()

            // Set initial floor selection based on default floor or previously selected floor
            let defaultFloorId = floorStack.defaultFloor
            let floorToSelect = self.floorToShowByBuilding[floorStackId] ?? self.getFloorById(defaultFloorId)

            if let floorToSelect = floorToSelect,
               let index = self.currentFloorStackFloors.firstIndex(where: { $0.id == floorToSelect.id }) {
                self.floorPicker.selectRow(index, inComponent: 0, animated: false)
            }

            self.isUpdatingPickers = false
        }
    }

    private func updateFloorsToShow() {
        floorToShowByBuilding.removeAll()
        allFloorStacks.forEach { floorStack in
            let floorsInStack = getFloorsForFloorStack(floorStack)
            if let floor = floorsInStack.first(where: { $0.elevation == currentElevation }) {
                floorToShowByBuilding[floorStack.id] = floor
            }
        }
    }

    private func showFloors(building: FloorStack) {
        let defaultFloor = getFloorById(building.defaultFloor)
        guard let floorToShow = floorToShowByBuilding[building.id] ?? defaultFloor else { return }
        let height = 10 * currentElevation

        let floorsInBuilding = getFloorsForFloorStack(building)

        floorsInBuilding.forEach { floor in
            if floor.id == floorToShow.id {
                mapView.updateState(
                    floor: floor,
                    state: FloorUpdateState(
                        altitude: height,
                        visible: true,
                        footprint: FloorUpdateState.Footprint(
                            altitude: -height,
                            height: height,
                            visible: currentElevation > 0
                        )
                    )
                )
            } else {
                mapView.updateState(
                    floor: floor,
                    state: FloorUpdateState(visible: false)
                )
            }
        }
    }

    private func openFacade(_ facade: Facade) {
        guard let floorStack = allFloorStacks.first(where: { $0.id == facade.floorStack }) else { return }

        print("[DynamicFocusManual] openFacade: \(floorStack.name) (setting opacity to 0)")

        // First, show the floor we want to see
        showFloors(building: floorStack)

        // Animate the facade out (hide it to reveal interior)
        mapView.animateState(facade: facade, state: FacadeUpdateState(opacity: 0.0))
    }

    private func closeFacade(_ facade: Facade) {
        let floorStack = allFloorStacks.first { $0.id == facade.floorStack }

        print("[DynamicFocusManual] closeFacade: \(floorStack?.name ?? "unknown") (setting opacity to 1)")

        // Animate the facade in (show it to hide interior)
        mapView.animateState(facade: facade, state: FacadeUpdateState(opacity: 1.0)) { [weak self] _ in
            guard let self = self, let floorStack = floorStack else { return }
            // Hide all floors for this building after animation completes
            let floorsInBuilding = self.getFloorsForFloorStack(floorStack)
            floorsInBuilding.forEach { floor in
                self.mapView.updateState(
                    floor: floor,
                    state: FloorUpdateState(visible: false)
                )
            }
        }
    }

    private func setupEventListeners() {
        // When facades come into view, switch to show that building's interior
        mapView.on(Events.facadesInViewChange) { [weak self] payload in
            guard let self = self, let payload = payload else { return }

            self.logEvent("facades-in-view-change: \(payload.facades.count) facade(s)")

            // If a facade is in view, switch to that building
            if !payload.facades.isEmpty {
                let facade = payload.facades.first!
                let floorStackId = facade.floorStack

                // Only switch if it's a different building
                if floorStackId != self.currentSelectedFloorStackId {
                    if let floorStack = self.allFloorStacks.first(where: { $0.id == floorStackId }) {
                        print("[DynamicFocusManual] Facade in view - switching to building: \(floorStack.name)")
                        // Don't focus camera - user is already panning to this location
                        self.switchToBuilding(floorStack, focusCamera: false)

                        // Update the building picker to reflect the change
                        if let buildingIndex = self.allFloorStacks.firstIndex(where: { $0.id == floorStackId }) {
                            DispatchQueue.main.async {
                                self.isUpdatingPickers = true
                                self.buildingPicker.selectRow(buildingIndex, inComponent: 0, animated: true)
                                self.isUpdatingPickers = false
                            }
                        }
                    }
                }
            } else {
                // No facades in view - switch to outdoor
                // Don't focus camera - user panned away, keep camera where it is
                if let outdoorFloorStack = self.allFloorStacks.first(where: { $0.type == .outdoor }),
                   outdoorFloorStack.id != self.currentSelectedFloorStackId {
                    print("[DynamicFocusManual] No facades in view - switching to outdoor")
                    self.switchToBuilding(outdoorFloorStack, focusCamera: false)

                    // Update the building picker to reflect the change
                    if let buildingIndex = self.allFloorStacks.firstIndex(where: { $0.id == outdoorFloorStack.id }) {
                        DispatchQueue.main.async {
                            self.isUpdatingPickers = true
                            self.buildingPicker.selectRow(buildingIndex, inComponent: 0, animated: true)
                            self.isUpdatingPickers = false
                        }
                    }
                }
            }
        }

        // Act on the floor-change event to update the level selector
        mapView.on(Events.floorChange) { [weak self] payload in
            guard let self = self, let payload = payload else { return }

            let newFloor = payload.floor
            self.currentElevation = newFloor.elevation
            self.updateFloorsToShow()

            guard let newFloorStack = newFloor.floorStack else { return }
            let newFloorStackId = newFloorStack.id
            print("[DynamicFocusManual] floor-change: \(newFloor.name) (floorStackId=\(newFloorStackId))")

            // Update UI pickers
            DispatchQueue.main.async {
                self.isUpdatingPickers = true

                if let buildingIndex = self.allFloorStacks.firstIndex(where: { $0.id == newFloorStackId }) {
                    self.buildingPicker.selectRow(buildingIndex, inComponent: 0, animated: true)
                }

                // Update floor picker selection if the floor is in current floor stack
                if let floorIndex = self.currentFloorStackFloors.firstIndex(where: { $0.id == newFloor.id }) {
                    self.floorPicker.selectRow(floorIndex, inComponent: 0, animated: true)
                }

                self.isUpdatingPickers = false
            }

            self.logEvent("floor-change: \(newFloor.name) (\(newFloorStack.name))")
        }
    }

    private func logEvent(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self?.eventLogLabel.text = "[\(timestamp)] \(message)"
        }
        print("[Event] \(message)")
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource

extension DynamicFocusManualDemoViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return allFloorStacks.count
        } else {
            return currentFloorStackFloors.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return allFloorStacks[row].name
        } else {
            return currentFloorStackFloors[row].name
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Skip if we're programmatically updating the pickers
        guard !isUpdatingPickers else { return }

        if pickerView.tag == 0 {
            // Building selected
            guard row < allFloorStacks.count else { return }
            let selectedFloorStack = allFloorStacks[row]
            switchToBuilding(selectedFloorStack)
        } else {
            // Floor selected
            guard row < currentFloorStackFloors.count else { return }
            let selectedFloor = currentFloorStackFloors[row]
            guard let floorStackId = currentSelectedFloorStackId else { return }

            // Update the floor to show for this building
            floorToShowByBuilding[floorStackId] = selectedFloor
            currentElevation = selectedFloor.elevation

            // Get the floor stack and show the selected floor
            if let floorStack = allFloorStacks.first(where: { $0.id == floorStackId }) {
                showFloors(building: floorStack)
            }

            print("[DynamicFocusManual] Floor selected: \(selectedFloor.name)")
        }
    }
}
