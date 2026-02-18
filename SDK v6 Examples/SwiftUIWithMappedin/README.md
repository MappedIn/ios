# SwiftUIWithMappedin

A sample SwiftUI application demonstrating how to integrate the Mappedin SDK for iOS v6 with SwiftUI using `UIViewRepresentable`.

## Features

- Display an interactive indoor map using Mappedin SDK v6
- SwiftUI integration via `UIViewRepresentable`
- Interactive labels on all named spaces
- Navigation path drawing between locations
- Interactive path drawing between locations
- Click event handling for labels, spaces, and paths
- Coordinate display on map taps

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

1. Open `SwiftUIWithMappedin.xcodeproj` in Xcode
2. Xcode will automatically fetch the Mappedin SDK dependency from:
   - Repository: `https://github.com/MappedIn/ios`
   - Version: `6.x.x`
3. Build and run the project on a simulator or device

## SDK Dependency

This project uses the Mappedin SDK via Swift Package Manager. The dependency is configured in the Xcode project to pull from:

```
https://github.com/MappedIn/ios
```

## Project Structure

```
SwiftUIWithMappedin/
├── SwiftUIWithMappedin.xcodeproj/   # Xcode project with SPM dependency
├── SwiftUIWithMappedin/
│   ├── SwiftUIWithMappedinApp.swift # App entry point
│   ├── ContentView.swift            # Main SwiftUI view
│   ├── MapViewRepresentable.swift   # UIViewRepresentable wrapping MapView
│   └── Assets.xcassets/             # App icons and colors
└── README.md
```

## Demo API Keys

This sample uses Mappedin demo API keys. See [Demo API Key Terms and Conditions](https://developer.mappedin.com/docs/demo-keys-and-maps) for more information.
