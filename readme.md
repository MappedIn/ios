# Mappedin iOS Samples

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMappedIn%2Fios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MappedIn/ios)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMappedIn%2Fios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MappedIn/ios)

This repo contains sample applications demonstrating different ways to integrate with the Mappedin SDK for iOS to render maps and build a custom indoor mapping experience. To learn more about ways to integrate with Mappedin, refer to [developer.mappedin.com](https://developer.mappedin.com/).

The Mappedin SDK for iOS enables you to build powerful and highly flexible indoor mapping experiences natively on iOS.

---

## Mappedin SDK for iOS v6 Samples

To read more about the Mappedin SDK for iOS, refer to [Getting Started with Mappedin SDK for iOS](https://developer.mappedin.com/ios-sdk/getting-started) and additional guides in the Mappedin developer docs.

The sample projects in this repo provide a key and secret to access demo maps. Production apps will need their own key and secret. Refer to [Create a Key & Secret](https://developer.mappedin.com/ios-sdk/getting-started#create-a-key--secret) for instructions on how to create your own.

The following table lists the sample activities that pertain to the latest version of the Mappedin SDK for iOS.

| **Sample**                   | **Description**                                                                                  | **Guide**                         |
| ---------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------- |
| [DisplayMapDemo]             | The most basic example to show a map.                                                            | [Getting Started]                 |
| [AreaShapesDemo]             | Demonstrates using shapes to show areas and route directions around closed areas.                | [Areas & Shapes]                  |
| [BlueDotDemo]                | Demonstrates using Blue Dot to show the user's position on the map.                              | [Blue Dot]                        |
| [BuildingFloorSelectionDemo] | Demonstrates switching between maps for venues with multiple floors and or multiple buildings.   | [Building & Floor Selection]      |
| [CacheMapDataDemo]           | Demonstrates how to use cached map data to modify data between reloads.                          | [Cache Map Data]                  |
| [CacheMVFDemo]               | Demonstrates how to use cached Mappedin Venue Format ([MVFv3][MVFv3]) files for quicker reloads. | [Cache MVF File]                  |
| [CameraDemo]                 | Demonstrates how to move the camera.                                                             | [Camera]                          |
| [ColorsAndTexturesDemo]      | Demonstrates how to apply custom colors and textures to the map.                                 | [Images, Textures & Colors]       |
| [DynamicFocusDemo]           | Demonstrates how to use Dynamic Focus.                                                           | [Dynamic Focus]                   |
| [DynamicFocusManualDemo]     | Demonstrates how to create a custom Dynamic Focus effect.                                        | [Custom Dynamic Focus]            |
| [Image3DDemo]                | Demonstrates how to add images on a map.                                                         | [Images, Textures & Colors]       |
| [InteractivityDemo]          | Demonstrates how to capture and act on touch events.                                             | [Interactivity]                   |
| [LabelsDemo]                 | Demonstrates adding rich labels to the map.                                                      | [Labels]                          |
| [LocationsDemo]              | Demonstrates using location profiles and categories.                                             | [Location Profiles & Categories]  |
| [MarkersDemo]                | Demonstrates adding HTML Markers to the map.                                                     | [Markers]                         |
| [ModelsDemo]                 | Demonstrates adding 3D models to the map.                                                        | [3D Models]                       |
| [MultiFloorViewDemo]         | Demonstrates using multi floor view.                                                             | [Multi Floor View & Stacked Maps] |
| [NavigationDemo]             | Demonstrates wayfinding and navigation across multiple floors.                                   | [Wayfinding]                      |
| [OfflineModeDemo]            | Demonstrates loading a map from a local Mappedin Venue Format ([MVFv3][MVFv3]) file.             | [Offline Mode]                    |
| [PathsDemo]                  | Demonstrates how to draw a path between two rooms.                                               | [Wayfinding]                      |
| [QueryDemo]                  | Demonstrates how to find the nearest room based on a coordinate and click event.                 |                                   |
| [SearchDemo]                 | Demonstrates how to use the suggest and search feature.                                          | [Search]                          |
| [StackedMapsDemo]            | Demonstrates how to use the stacked maps.                                                        | [Multi Floor View & Stacked Maps] |
| [Text3DDemo]                 | Demonstrates how to use Text3D labels.                                                           | [Flat Text]                       |
| [TurnByTurnDemo]             | Demonstrates how to use turn by turn directions.                                                 | [Turn-by-Turn Directions]         |

[DisplayMapDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/DisplayMapDemoViewController.swift
[AreaShapesDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/AreaShapesDemoViewController.swift
[BlueDotDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/BlueDotDemoViewController.swift
[BuildingFloorSelectionDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/BuildingFloorSelectionDemoViewController.swift
[CacheMapDataDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/CacheMapDataDemoViewController.swift
[CacheMVFDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/CacheMVFDemoViewController.swift
[CameraDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/CameraDemoViewController.swift
[ColorsAndTexturesDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/ColorsAndTexturesDemoViewController.swift
[DynamicFocusDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/DynamicFocusDemoViewController.swift
[DynamicFocusManualDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/DynamicFocusManualDemoViewController.swift
[Image3DDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/Image3DDemoViewController.swift
[InteractivityDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/InteractivityDemoViewController.swift
[LabelsDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/LabelsDemoViewController.swift
[LocationsDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/LocationsDemoViewController.swift
[MarkersDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/MarkersDemoViewController.swift
[ModelsDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/ModelsDemoViewController
[MultiFloorViewDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/MultiFloorViewDemoViewController.swift
[NavigationDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/NavigationDemoViewController.swift
[OfflineModeDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/OfflineModeDemoViewController.swift
[PathsDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/PathsDemoViewController.swift
[QueryDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/QueryDemoViewController.swift
[SearchDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/SearchDemoViewController.swift
[StackedMapsDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/StackedMapsDemoViewController.swift
[Text3DDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/Text3DDemoViewController.swift
[TurnByTurnDemo]: ./SDK%20v6%20Examples/PlaygroundSamples/PlaygroundSamples/TurnByTurnDemoViewController.swift
[MVFv3]: https://developer.mappedin.com/docs/mvf/v3/getting-started
[Getting Started]: https://developer.mappedin.com/ios-sdk/getting-started
[Areas & Shapes]: https://developer.mappedin.com/ios-sdk/shapes
[Blue Dot]: https://developer.mappedin.com/ios-sdk/blue-dot
[Building & Floor Selection]: https://developer.mappedin.com/ios-sdk/level-selection
[Cache Map Data]: https://developer.mappedin.com/ios-sdk/getting-started#caching-and-loading-map-data-as-json
[Cache MVF File]: https://developer.mappedin.com/ios-sdk/getting-started#caching-and-loading-map-data-as-a-mvf-file
[Camera]: https://developer.mappedin.com/ios-sdk/camera
[Dynamic Focus]: https://developer.mappedin.com/ios-sdk/dynamic-focus
[Custom Dynamic Focus]: https://developer.mappedin.com/ios-sdk/dynamic-focus#implementing-dynamic-focus-using-mapview
[Images, Textures & Colors]: https://developer.mappedin.com/ios-sdk/images-textures
[Interactivity]: https://developer.mappedin.com/ios-sdk/interactivity
[Labels]: https://developer.mappedin.com/ios-sdk/labels
[Location Profiles & Categories]: https://developer.mappedin.com/ios-sdk/location-profiles-categories
[Markers]: https://developer.mappedin.com/ios-sdk/markers
[3D Models]: https://developer.mappedin.com/ios-sdk/3d-models
[Multi Floor View & Stacked Maps]: https://developer.mappedin.com/ios-sdk/stacked-maps
[Wayfinding]: https://developer.mappedin.com/ios-sdk/wayfinding
[Offline Mode]: https://developer.mappedin.com/ios-sdk/getting-started#offline-loading-mode
[Search]: https://developer.mappedin.com/ios-sdk/enterprise-data#search
[Flat Text]: https://developer.mappedin.com/ios-sdk/labels#flat-labels-with-text3d
[Turn-by-Turn Directions]: https://developer.mappedin.com/ios-sdk/wayfinding#turn-by-turn-directions

---

## Additional Resources

- [Mappedin Developer Site](https://developer.mappedin.com/)
- [Mappedin SDK for iOS Getting Started Guide](https://developer.mappedin.com/ios-sdk/getting-started)
- [Mappedin SDK for iOS API Docs](https://docs.mappedin.com/ios-sdk-api/v6/latest/documentation/mappedin/)
- [Release Notes](https://developer.mappedin.com/ios-sdk/release-notes)

---
