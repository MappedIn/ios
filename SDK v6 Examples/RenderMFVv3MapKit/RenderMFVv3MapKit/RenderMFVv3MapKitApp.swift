// RenderMFVv3MapKitApp.swift
//
// Entry point for the Render MVF v3 with MapKit example app.
//
// This app demonstrates how to download a Mappedin Venue Format v3 (MVF v3)
// bundle and render it using Apple's MapKit framework on iOS. MVF v3 is a
// GeoJSON-based format containing indoor map geometry and styling data.
//
// The app performs the following steps:
// 1. Authenticates with the Mappedin API to get an access token.
// 2. Downloads the MVF v3 zip bundle for a venue.
// 3. Extracts and parses the GeoJSON geometry and style data.
// 4. Renders the indoor map as overlays on an MKMapView.
//
// For more information, see:
// - Getting Started with MVF v3: https://developer.mappedin.com/docs/mvf/v3/getting-started
// - Demo Keys & Maps: https://developer.mappedin.com/docs/demo-keys-and-maps

import SwiftUI

@main
struct RenderMFVv3MapKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
