// ContentView.swift
//
// Main SwiftUI view that displays the indoor map.
//
// This file contains:
// - ContentView: The top-level SwiftUI view that embeds the MapKit map and
//   triggers loading of the MVF v3 venue data.
// - MapViewRepresentable: A UIViewRepresentable that wraps MKMapView for use
//   in SwiftUI, with a Coordinator that handles the MKMapViewDelegate callbacks.
//
// The Coordinator is responsible for rendering each overlay with the correct
// style (fill color, stroke color, line width) by looking up the overlay's
// geometry ID in the MapViewModel's styleLookup dictionary.

import MapKit
import SwiftUI

// MARK: - ContentView

/// The main view of the app. Embeds an MKMapView and loads the MVF v3 data.
struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack {
            // The MapKit map view, wrapped for SwiftUI.
            MapViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

            // Show a loading indicator while the venue data is being downloaded
            // and processed.
            if viewModel.isLoading {
                ProgressView("Loading venue...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }

            // Display an error message if something goes wrong.
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
            }
        }
    }
}

// MARK: - MapViewRepresentable

/// Wraps MKMapView as a UIViewRepresentable for use in SwiftUI.
///
/// This representable:
/// - Creates and configures an MKMapView instance.
/// - Provides a Coordinator that acts as the MKMapViewDelegate.
/// - Triggers the venue loading process when the view first appears.
struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Start loading the MVF v3 data. The loadVenue method will:
        // 1. Fetch an access token from the Mappedin API.
        // 2. Download and extract the MVF v3 zip bundle.
        // 3. Parse the GeoJSON and add overlays to this map view.
        Task {
            await viewModel.loadVenue(mapView: mapView)
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // No dynamic updates needed; overlays are added once during loading.
    }

    // MARK: - Coordinator (MKMapViewDelegate)

    /// Coordinator that handles MKMapViewDelegate callbacks.
    ///
    /// The primary responsibility is implementing `rendererFor overlay:` to
    /// provide the correct visual style for each geometry overlay. It does this
    /// by looking up the overlay's title (which stores the geometry ID) in the
    /// MapViewModel's styleLookup dictionary.
    class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        /// Provides a renderer for each overlay added to the map.
        ///
        /// MapKit calls this method for every overlay. The overlay's title property
        /// contains the geometry ID (set during loading in MapViewModel). This ID
        /// is used to look up the OverlayStyle from the styleLookup dictionary,
        /// which determines the fill color, stroke color, and line width.
        ///
        /// Overlay types handled:
        /// - MKPolygon / MKMultiPolygon: Filled shapes (rooms, hallways, desks).
        /// - MKPolyline / MKMultiPolyline: Line shapes (walls, exterior walls).
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Look up the style for this geometry using its ID stored in the title.
            // Note: MKOverlay.title is String?? (doubly optional) because the protocol
            // property is optional and its return type is also optional.
            let style = (overlay.title ?? nil).flatMap { viewModel.styleLookup[$0] }

            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                if let style = style {
                    renderer.fillColor = style.fillColor
                    renderer.strokeColor = style.strokeColor
                    renderer.lineWidth = style.lineWidth
                } else {
                    // Default style for geometry not found in the style lookup.
                    renderer.fillColor = UIColor(hex: "#f5f5f5")
                }
                return renderer
            } else if let multiPolygon = overlay as? MKMultiPolygon {
                let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
                if let style = style {
                    renderer.fillColor = style.fillColor
                    renderer.strokeColor = style.strokeColor
                    renderer.lineWidth = style.lineWidth
                } else {
                    renderer.fillColor = UIColor(hex: "#f5f5f5")
                }
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if let style = style {
                    renderer.strokeColor = style.strokeColor
                    renderer.lineWidth = style.lineWidth
                } else {
                    // Default wall color: light gray for visibility against the map.
                    renderer.strokeColor = UIColor(hex: "#dddddd")
                    renderer.lineWidth = 2.0
                }
                return renderer
            } else if let multiPolyline = overlay as? MKMultiPolyline {
                let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
                if let style = style {
                    renderer.strokeColor = style.strokeColor
                    renderer.lineWidth = style.lineWidth
                } else {
                    renderer.strokeColor = UIColor(hex: "#dddddd")
                    renderer.lineWidth = 2.0
                }
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
