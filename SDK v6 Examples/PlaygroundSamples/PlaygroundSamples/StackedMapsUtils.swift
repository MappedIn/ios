import Foundation
import Mappedin

/// Options for expanding floors in a stacked view.
public struct ExpandOptions {
	/// The vertical spacing between floors in meters. Default: 10
	public let distanceBetweenFloors: Double
	/// Whether to animate the floor expansion. Default: true
	public let animate: Bool
	/// The camera pan mode to use ("default" or "elevation"). Default: "elevation"
	public let cameraPanMode: String

	public init(
		distanceBetweenFloors: Double = 10.0,
		animate: Bool = true,
		cameraPanMode: String = "elevation"
	) {
		self.distanceBetweenFloors = distanceBetweenFloors
		self.animate = animate
		self.cameraPanMode = cameraPanMode
	}
}

/// Options for collapsing floors back to their original positions.
public struct CollapseOptions {
	/// Whether to animate the floor collapse. Default: true
	public let animate: Bool

	public init(animate: Bool = true) {
		self.animate = animate
	}
}

/// Utility class for managing stacked floor views.
///
/// Provides functions to expand all floors vertically (stacked view) and collapse them back
/// to a single floor view. This creates a 3D exploded view effect where all floors are visible
/// at different altitudes.
///
/// Example usage:
/// ```swift
/// // Expand floors with default options
/// StackedMapsUtils.expandFloors(mapView: mapView)
///
/// // Expand floors with custom gap
/// StackedMapsUtils.expandFloors(mapView: mapView, options: ExpandOptions(distanceBetweenFloors: 20.0))
///
/// // Collapse floors back
/// StackedMapsUtils.collapseFloors(mapView: mapView)
/// ```
public class StackedMapsUtils {

	/// Expands all floors vertically to create a stacked view.
	///
	/// Each floor is positioned at an altitude based on its elevation multiplied by the
	/// distance between floors. This creates a 3D exploded view where all floors are visible.
	///
	/// - Parameters:
	///   - mapView: The MapView instance
	///   - options: Options controlling the expansion behavior
	public static func expandFloors(
		mapView: MapView,
		options: ExpandOptions = ExpandOptions()
	) {
		// Set camera pan mode to elevation for better navigation in stacked view
		mapView.camera.setPanMode(options.cameraPanMode)

		// Get the current floor ID to identify the active floor
		mapView.currentFloor { currentFloorResult in
			let currentFloorId: String?
			switch currentFloorResult {
			case .success(let floor):
				currentFloorId = floor?.id
			case .failure:
				currentFloorId = nil
			}

			// Get all floors
			mapView.mapData.getByType(MapDataType.floor) { (result: Result<[Floor], Error>) in
				switch result {
				case .success(let floors):
					for floor in floors {
						let newAltitude = floor.elevation * options.distanceBetweenFloors
						let isCurrentFloor = floor.id == currentFloorId

						// First, make sure the floor is visible
						mapView.getState(floor: floor) { stateResult in
							switch stateResult {
							case .success(let currentState):
								if let state = currentState,
								   (!state.visible || !state.geometry.visible) {
							// Make the floor visible first with 0 opacity if not current
								mapView.updateState(
									floor: floor,
									state: FloorUpdateState(
										altitude: 0.0,
										visible: true,
										geometry: FloorUpdateState.Geometry(
											opacity: isCurrentFloor ? 1.0 : 0.0,
											visible: true
										)
									)
								)
								}

								// Then animate or update to the new altitude
								if options.animate {
									mapView.animateState(
										floor: floor,
										state: FloorUpdateState(
											altitude: newAltitude,
											geometry: FloorUpdateState.Geometry(
												opacity: 1.0
											)
										)
									)
								} else {
									mapView.updateState(
										floor: floor,
										state: FloorUpdateState(
											altitude: newAltitude,
											visible: true,
											geometry: FloorUpdateState.Geometry(
												opacity: 1.0,
												visible: true
											)
										)
									)
								}
							case .failure:
								break
							}
						}
					}
				case .failure:
					break
				}
			}
		}
	}

	/// Collapses all floors back to their original positions.
	///
	/// Floors are returned to altitude 0, and only the current floor remains fully visible.
	/// Other floors are hidden to restore the standard single-floor view.
	///
	/// - Parameters:
	///   - mapView: The MapView instance
	///   - options: Options controlling the collapse behavior
	public static func collapseFloors(
		mapView: MapView,
		options: CollapseOptions = CollapseOptions()
	) {
		// Reset camera pan mode to default
		mapView.camera.setPanMode("default")

		// Get the current floor ID to identify the active floor
		mapView.currentFloor { currentFloorResult in
			let currentFloorId: String?
			switch currentFloorResult {
			case .success(let floor):
				currentFloorId = floor?.id
			case .failure:
				currentFloorId = nil
			}

			// Get all floors
			mapView.mapData.getByType(MapDataType.floor) { (result: Result<[Floor], Error>) in
				switch result {
				case .success(let floors):
					for floor in floors {
						let isCurrentFloor = floor.id == currentFloorId

						if options.animate {
							// Animate to altitude 0 and fade out non-current floors
							mapView.animateState(
								floor: floor,
								state: FloorUpdateState(
									altitude: 0.0,
									geometry: FloorUpdateState.Geometry(
										opacity: isCurrentFloor ? 1.0 : 0.0
									)
								)
							)

							// After animation, hide non-current floors
							if !isCurrentFloor {
								DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
									mapView.updateState(
										floor: floor,
										state: FloorUpdateState(
											altitude: 0.0,
											visible: false,
											geometry: FloorUpdateState.Geometry(
												opacity: 0.0,
												visible: false
											)
										)
									)
								}
							}
						} else {
							mapView.updateState(
								floor: floor,
								state: FloorUpdateState(
									altitude: 0.0,
									visible: isCurrentFloor,
									geometry: FloorUpdateState.Geometry(
										opacity: isCurrentFloor ? 1.0 : 0.0,
										visible: isCurrentFloor
									)
								)
							)
						}
					}
				case .failure:
					break
				}
			}
		}
	}
}

