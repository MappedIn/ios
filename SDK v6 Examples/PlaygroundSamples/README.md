# PlaygroundSamples

This repo contains sample applications demonstrating different ways to integrate with the Mappedin SDK for Android to render maps and build a custom indoor mapping experience. To learn more about ways to integrate with Mappedin, refer to [developer.mappedin.com](https://developer.mappedin.com/).

The Mappedin SDK for Android enables you to build powerful and highly flexible indoor mapping experiences natively on Android.

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

1. Open `PlaygroundSamples.xcodeproj` in Xcode
2. Xcode will automatically fetch the Mappedin SDK dependency from:
   - Repository: `https://github.com/MappedIn/ios`
   - Version: `6.x.x`
3. Build and run the project on a simulator or device

## SDK Dependency

This project uses the Mappedin SDK via Swift Package Manager. The dependency is configured in the Xcode project to pull from:

```
https://github.com/MappedIn/ios
```

## Sample Demos

The app includes the following sample demonstrations:

1. **Areas & Shapes** - Demonstrates drawing shapes from areas, labeling them, and routing with zone avoidance
2. **Building & Floor Selection** - Shows how to navigate between buildings and floors
3. **Camera** - Demonstrates camera controls including pitch, zoom, animate, and reset
4. **Display a Map** - Basic map display example
5. **Image3D** - Shows how to add 3D images to spaces (arena floor examples)
6. **Interactivity** - Demonstrates click events on labels, spaces, and paths
7. **Labels** - Shows custom label styling and interactive label removal
8. **Markers** - Demonstrates adding annotation markers to the map
9. **Models** - Shows how to add 3D models from GLB files
10. **Navigation** - Demonstrates navigation path drawing with custom markers
11. **Paths** - Interactive path creation between spaces
12. **Query** - Shows spatial queries to find nearest spaces
13. **Search** - Demonstrates search functionality with autocomplete

## Trial API Keys

The samples use Mappedin trial API keys. See [Trial API Key Terms and Conditions](https://developer.mappedin.com/docs/demo-keys-and-maps) for more information.

## Project Structure

```
PlaygroundSamples/
├── PlaygroundSamples.xcodeproj/     # Xcode project with SPM dependency
├── PlaygroundSamples/
│   ├── AppDelegate.swift            # App delegate
│   ├── SceneDelegate.swift          # Scene delegate
│   ├── ViewController.swift         # Main menu with sample list
│   ├── *DemoViewController.swift    # Individual demo view controllers
│   ├── Base.lproj/                  # Storyboards
│   ├── Assets.xcassets/             # App icons and colors
│   ├── 3d_assets/                   # GLB 3D model files
│   ├── arena_*.png                  # Arena floor images
│   ├── model_positions.json         # 3D model placement data
│   └── Info.plist                   # App configuration
└── README.md
```
