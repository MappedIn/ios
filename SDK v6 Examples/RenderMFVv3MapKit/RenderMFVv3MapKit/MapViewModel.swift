// MapViewModel.swift
//
// Core logic for downloading, parsing, and rendering an MVF v3 bundle.
//
// This file handles the full pipeline:
// 1. Authenticate with the Mappedin REST API to obtain an access token.
// 2. Download the MVF v3 zip bundle for a given venue/map ID.
// 3. Extract and parse GeoJSON files from the zip (manifest, floors, geometry).
// 4. Parse the default-style.json to build a lookup from geometry ID to style.
// 5. Decode the GeoJSON with MKGeoJSONDecoder and add overlays to an MKMapView.
//
// MVF v3 Data Model Overview:
// - manifest.geojson: Contains the center coordinate of the venue.
// - floors.geojson: Lists all floors with their IDs and elevations.
// - geometry/{floorId}.geojson: All geometry (rooms, walls, etc.) for a floor.
// - default-style.json: Named style groups (e.g. "Rooms", "Walls") that map
//   geometry IDs to visual properties like color and line width.
//
// For the full MVF v3 specification, see:
// https://developer.mappedin.com/docs/mvf/v3/getting-started

import Foundation
import MapKit
import ZIPFoundation

// MARK: - API Response Models

/// Response from the Mappedin API Key token endpoint.
/// The access token is used to authenticate subsequent API calls.
struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

/// Response from the Get Venue MVF endpoint.
/// Contains a URL to download the MVF v3 zip bundle.
struct VenueResponse: Codable {
    let url: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case url
        case updatedAt = "updated_at"
    }
}

// MARK: - Overlay Style Model

/// Defines the visual style for a geometry overlay on the map.
/// Each geometry in the MVF v3 bundle is assigned a style based on the
/// default-style.json file, which groups geometries by type (Rooms, Walls, etc.).
struct OverlayStyle {
    let fillColor: UIColor
    let strokeColor: UIColor
    let lineWidth: CGFloat
}

// MARK: - MapViewModel

/// ViewModel that manages the MVF v3 data loading pipeline and map state.
///
/// The loading flow is:
/// 1. Call `loadVenue()` which orchestrates the full pipeline.
/// 2. Fetch an access token from the Mappedin API.
/// 3. Download the MVF v3 zip using the token.
/// 4. Extract and parse the zip contents.
/// 5. Build the style lookup and add overlays to the map view.
class MapViewModel: ObservableObject {

    // See Demo API key Terms and Conditions
    // https://developer.mappedin.com/docs/demo-keys-and-maps
    private let apiKey = "mik_yeBk0Vf0nNJtpesfu560e07e5"
    private let apiSecret = "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022"

    // The Mappedin Map ID for the Demo Office map.
    private let mapId = "64ef49e662fd90fe020bee61"

    // The floor elevation to display. Elevation 0 is typically the ground floor.
    private let elevation: Int = 0

    /// A lookup table mapping geometry IDs to their visual styles.
    /// Built from default-style.json when the MVF v3 bundle is parsed.
    /// Used by the MKMapViewDelegate to style each overlay in rendererFor:.
    var styleLookup: [String: OverlayStyle] = [:]

    /// Published property to indicate loading state for the UI.
    @Published var isLoading = true

    /// Published property to surface errors to the UI.
    @Published var errorMessage: String?

    // MARK: - Public API

    /// Main entry point: loads the venue data and adds overlays to the map.
    ///
    /// - Parameter mapView: The MKMapView to add overlays to and center on the venue.
    func loadVenue(mapView: MKMapView) async {
        do {
            // Step 1: Authenticate with the Mappedin API.
            let token = try await getAccessToken()

            // Step 2: Download the MVF v3 zip bundle.
            let archiveURL = try await downloadMVFBundle(accessToken: token)

            // Step 3: Extract and process the zip contents, adding overlays to the map.
            try await processZipFile(at: archiveURL, mapView: mapView)

            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Error loading venue: \(error)")
        }
    }

    // MARK: - Step 1: Authentication

    /// Exchanges the API key and secret for a JWT access token.
    ///
    /// Makes a POST request to the Mappedin API Key token endpoint:
    /// https://app.mappedin.com/api/v1/api-key/token
    ///
    /// - Returns: A JWT access token string.
    private func getAccessToken() async throws -> String {
        let url = URL(string: "https://app.mappedin.com/api/v1/api-key/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "key": apiKey,
            "secret": apiSecret
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        return response.accessToken
    }

    // MARK: - Step 2: Download MVF v3 Bundle

    /// Downloads the MVF v3 zip bundle for the configured venue.
    ///
    /// First calls the Get Venue MVF endpoint to get a download URL:
    /// https://app.mappedin.com/api/venue/{mapId}/mvf?version=3.0.0
    ///
    /// The `version=3.0.0` query parameter specifies the MVF v3 format.
    /// Then downloads the zip file and saves it to a temporary location.
    ///
    /// - Parameter accessToken: The JWT token from step 1.
    /// - Returns: A file URL to the downloaded zip file.
    private func downloadMVFBundle(accessToken: String) async throws -> URL {
        // Request the MVF download URL from the Mappedin API.
        // The version=3.0.0 parameter ensures we get the v3 format.
        let url = URL(string: "https://app.mappedin.com/api/venue/\(mapId)/mvf?version=3.0.0")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let venueResponse = try JSONDecoder().decode(VenueResponse.self, from: data)

        // Download the actual zip file from the URL provided in the response.
        let zipUrl = URL(string: venueResponse.url)!
        let (zipData, _) = try await URLSession.shared.data(from: zipUrl)

        // Save the zip data to a temporary file for extraction.
        let tempDir = FileManager.default.temporaryDirectory
        let zipPath = tempDir.appendingPathComponent("venue_mvfv3.zip")
        try zipData.write(to: zipPath)

        return zipPath
    }

    // MARK: - Step 3: Extract and Process Zip

    /// Extracts the MVF v3 zip and processes its contents.
    ///
    /// The MVF v3 zip contains:
    /// - manifest.geojson: Center coordinate of the venue.
    /// - floors.geojson: Floor list with IDs and elevations.
    /// - geometry/{floorId}.geojson: All geometry for a given floor.
    /// - default-style.json: Style definitions mapping geometry IDs to colors.
    ///
    /// Unlike MVF v2, which separates geometry into space/ and obstruction/ folders,
    /// MVF v3 combines all geometry into a single geometry/{floorId}.geojson file.
    ///
    /// - Parameters:
    ///   - path: The file URL of the downloaded zip.
    ///   - mapView: The MKMapView to add overlays to.
    private func processZipFile(at path: URL, mapView: MKMapView) async throws {
        let archive: Archive
        do {
            archive = try Archive(url: path, accessMode: .read)
        } catch {
            throw NSError(
                domain: "VenueError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to read ZIP archive: \(error.localizedDescription)"])
        }

        // Load the manifest to get the venue's center coordinate.
        let manifestData = try loadFileFromZip(archive: archive, path: "manifest.geojson")

        // Load the style definitions to determine how geometry should be rendered.
        // In MVF v3, this file is named "default-style.json" (vs "styles.json" in v2).
        let stylesData = try loadFileFromZip(archive: archive, path: "default-style.json")

        // Load the floor list to find the floor ID for the desired elevation.
        // In MVF v3, this file is named "floors.geojson" (vs "floor.geojson" in v2).
        let floorData = try loadFileFromZip(archive: archive, path: "floors.geojson")

        // Parse floors.geojson to find the floor ID matching our target elevation.
        // Each floor feature has properties including "id" and "elevation".
        let floorJson = try JSONSerialization.jsonObject(with: floorData) as! [String: Any]
        let floorFeatures = floorJson["features"] as! [[String: Any]]

        var floorId: String = ""
        for feature in floorFeatures {
            let properties = feature["properties"] as! [String: Any]
            if let floorElevation = properties["elevation"] as? Int,
               floorElevation == elevation {
                floorId = properties["id"] as! String
                break
            }
        }

        guard !floorId.isEmpty else {
            throw NSError(
                domain: "VenueError", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No floor found for elevation \(elevation)"])
        }

        // In MVF v3, all geometry for a floor is in a single file: geometry/{floorId}.geojson
        // This replaces the separate space/{floorId}.geojson and obstruction/{floorId}.geojson
        // files used in MVF v2.
        let geometryData = try loadFileFromZip(archive: archive, path: "geometry/\(floorId).geojson")

        // Build the style lookup and render the geometry on the map.
        try await initVisualization(
            manifest: manifestData,
            styles: stylesData,
            geometryData: geometryData,
            mapView: mapView
        )
    }

    /// Extracts a single file from the zip archive and returns its raw data.
    ///
    /// - Parameters:
    ///   - archive: The ZIPFoundation Archive to read from.
    ///   - path: The relative path of the file within the zip.
    /// - Returns: The raw Data of the extracted file.
    private func loadFileFromZip(archive: Archive, path: String) throws -> Data {
        guard let entry = archive[path] else {
            throw NSError(
                domain: "ZipError", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "File not found in zip: \(path)"])
        }

        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }
        return data
    }

    // MARK: - Step 4 & 5: Build Styles and Render Geometry

    /// Parses the MVF v3 data and creates MapKit overlays.
    ///
    /// This method:
    /// 1. Centers the map on the venue using the manifest's coordinates.
    /// 2. Parses default-style.json to build a [geometryId: OverlayStyle] lookup.
    /// 3. Decodes the geometry GeoJSON with MKGeoJSONDecoder.
    /// 4. Adds each geometry as a styled overlay to the map.
    ///
    /// - Parameters:
    ///   - manifest: Raw data of manifest.geojson.
    ///   - styles: Raw data of default-style.json.
    ///   - geometryData: Raw data of geometry/{floorId}.geojson.
    ///   - mapView: The MKMapView to render on.
    private func initVisualization(
        manifest: Data, styles: Data, geometryData: Data, mapView: MKMapView
    ) async throws {

        // --- Center the map on the venue ---
        // The manifest.geojson contains a single feature whose geometry is a Point
        // with the venue's center coordinate in [longitude, latitude] order.
        let manifestJson = try JSONSerialization.jsonObject(with: manifest) as! [String: Any]
        let features = (manifestJson["features"] as! [[String: Any]])[0]
        let geometry = features["geometry"] as! [String: Any]
        let coordinates = geometry["coordinates"] as! [Double]

        let center = CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])

        await MainActor.run {
            let region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 100,
                longitudinalMeters: 100
            )
            mapView.setRegion(region, animated: false)
        }

        // --- Parse default-style.json ---
        // MVF v3 styles are organized as named groups. Each group has:
        // - "color": A hex color string (e.g. "#e0e0e0") for polygon fills.
        // - "buffer": A numeric value used as line width for lineString geometry.
        // - "geometryAnchors": An array of {floorId, geometryId} objects that link
        //   geometry features to this style group.
        //
        // Example style groups: "Rooms", "Hallways", "Walls", "ExteriorWalls", "Desks".
        //
        // This differs from MVF v2, which used a flat dictionary where each key mapped
        // to an object with a "polygons" array and a "color" property.
        guard let stylesDict = try JSONSerialization.jsonObject(with: styles) as? [String: Any] else {
            return
        }

        buildStyleLookup(from: stylesDict)

        // --- Decode geometry and add overlays ---
        // Use MKGeoJSONDecoder to parse the GeoJSON into MKGeoJSONFeature objects.
        // Each feature's geometry is automatically converted to the appropriate MapKit
        // type: MKPolygon for Polygon, MKPolyline for LineString, etc.
        let decoder = MKGeoJSONDecoder()

        guard let geoFeatures = try decoder.decode(geometryData) as? [MKGeoJSONFeature] else {
            return
        }

        await MainActor.run {
            for feature in geoFeatures {
                // Extract the geometry ID from the feature's properties.
                // This ID is used to look up the style in our styleLookup dictionary.
                guard let featureData = feature.properties,
                      let properties = try? JSONSerialization.jsonObject(with: featureData) as? [String: Any],
                      let geometryId = properties["id"] as? String else {
                    continue
                }

                // Process each geometry object in the feature.
                // A feature may contain multiple geometry objects (e.g. MultiPolygon).
                for geo in feature.geometry {
                    if let polygon = geo as? MKPolygon {
                        // Store the geometry ID in the overlay's title property.
                        // The MKMapViewDelegate uses this to look up the correct style
                        // when rendering the overlay.
                        polygon.title = geometryId
                        mapView.addOverlay(polygon)
                    } else if let multiPolygon = geo as? MKMultiPolygon {
                        // MKMultiPolygon contains multiple polygons as a single overlay.
                        multiPolygon.title = geometryId
                        mapView.addOverlay(multiPolygon)
                    } else if let polyline = geo as? MKPolyline {
                        polyline.title = geometryId
                        mapView.addOverlay(polyline)
                    } else if let multiPolyline = geo as? MKMultiPolyline {
                        multiPolyline.title = geometryId
                        mapView.addOverlay(multiPolyline)
                    }
                }
            }
        }
    }

    // MARK: - Style Lookup Builder

    /// Builds a reverse lookup table from geometry IDs to overlay styles.
    ///
    /// Iterates over all style groups in default-style.json. Each group's
    /// "geometryAnchors" array contains {floorId, geometryId} pairs. For each
    /// anchor, we create an OverlayStyle and store it keyed by geometryId.
    ///
    /// Style groups are handled as follows:
    /// - Groups with a "color" property (e.g. Rooms, Hallways, Desks):
    ///   The color is used as the fill color for polygon overlays.
    /// - Groups with a "buffer" property (e.g. Walls, ExteriorWalls):
    ///   These represent line geometry. The buffer value controls line width,
    ///   and a gray stroke color is applied for visibility.
    /// - Groups with both "color" and "buffer": The color is used as fill,
    ///   and the buffer determines line width.
    ///
    /// - Parameter stylesDict: The parsed default-style.json dictionary.
    private func buildStyleLookup(from stylesDict: [String: Any]) {
        for (groupName, value) in stylesDict {
            guard let group = value as? [String: Any],
                  let anchors = group["geometryAnchors"] as? [[String: Any]] else {
                continue
            }

            let color = group["color"] as? String
            let buffer = group["buffer"] as? Double

            // Determine the style based on available properties.
            // Groups like "Walls" and "ExteriorWalls" use buffer for line width and
            // a gray stroke color, while "Rooms", "Hallways", and "Desks" use fill color.
            let style: OverlayStyle
            if let color = color, buffer != nil {
                // Has both color and buffer (filled geometry with a border).
                style = OverlayStyle(
                    fillColor: UIColor(hex: color).withAlphaComponent(0.95),
                    strokeColor: .clear,
                    lineWidth: CGFloat(buffer ?? 1.0)
                )
            } else if let buffer = buffer {
                // Line geometry (walls, exterior walls) - no fill, use stroke.
                // Wall colors are hardcoded to gray shades for visibility, matching
                // the approach used in the MVF v3 MapKit JS example.
                let strokeHex: String
                let widthMultiplier: Double
                if groupName.lowercased().contains("exterior") {
                    strokeHex = "#acacac"
                    widthMultiplier = 2.0
                } else {
                    strokeHex = "#b2b2b2"
                    widthMultiplier = 1.5
                }
                style = OverlayStyle(
                    fillColor: .clear,
                    strokeColor: UIColor(hex: strokeHex),
                    lineWidth: CGFloat(buffer * widthMultiplier)
                )
            } else if let color = color {
                // Polygon geometry (rooms, hallways, desks) - filled with the style color.
                style = OverlayStyle(
                    fillColor: UIColor(hex: color).withAlphaComponent(0.95),
                    strokeColor: .clear,
                    lineWidth: 0
                )
            } else {
                // Fallback for unrecognized style groups.
                style = OverlayStyle(
                    fillColor: UIColor(hex: "#f5f5f5"),
                    strokeColor: .clear,
                    lineWidth: 0
                )
            }

            // Map each geometry anchor's geometryId to this style.
            for anchor in anchors {
                if let geometryId = anchor["geometryId"] as? String {
                    styleLookup[geometryId] = style
                }
            }
        }
    }
}
