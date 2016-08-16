# MappedIn iOS SDK Example

This repo contains a simple example to get you started with the MappedIn iOS SDK. Before you can do anything, make sure you have an API key from MappedIn. Talk to your representative to get one.

## Changes

*v0.10.9*

* Enable orthographic mode to be enabled before map is rendered
* Make clearHighlightedPolygons clear all polygons on all maps

*v0.10.5*

* Fix bug with 3D model parsing happening on main thread

*v0.10.4*

* Fix directions bug
* Fix MapViewMarker bug

*v0.10.2*

* Moved 3D model loading process into getVenue call

*v0.10.0*

* Improved georeferencing accuracy.
* New methods on Coordinate let you get the meters from another Coordinate, Path, or Polygon and check whether a Coordinate is inside a Polygon.
* Renamed a number of method signatures to align with Swift 3.0's naming conventions. 

*v0.9.0*

* Can now wayfind to/from Coordinates generated from arbitrary lat/longs. The path will connect directly to the closest real walkable node.
* Markers can now be positioned and rotated dynamically. Just change their rotation property, or give them a new Coordinate

*v0.8.0*

* Added iOS8 support to MapView (required custom OBJ file loader)
* Improvements to MapView loading time
* Added written directions for turns
* Added analytics
* Call `Analytics.selectedLocation(location)` and `Analytics.selectedCategory(category)` when the user selects locations and categories in your application (taps on a polygon, picks a category/location out of a list, selects a location/category during search, etc). It is up to your discretion what should count for your application. 
* Implemented MappedIn.Delegate for SDK configuration and lifecycle handling
* The Direction class has been changed to the Directions.Instruction class
* The Directions.directions property has been renamed to Directions.instructions
* The Directions.Instruction.instruction property has been renamed to Directions.Instruction.description
* You must add a property called "mappedInDelegate" to your AppDelegate with an instance of MappedIn.Delegate
* In Swift:
```swift
class AppDelegate: UIApplicationDelegate {
  let mappedInDelegate = MappedIn.Delegate(AppDelegate)
```
* In Objective-C:
```objective-c
- (id)init {
  MIDelegate *mappedInDelegate = [[MIDelegate alloc] init:AppDelegate.self]
```
* The locationGenerator argument on getVenue() is being replaced by the Delegate.generateLocation method
* To use a custom generateLocation method, create your own Delegate class inheriting from MappedIn.Delegate and override the Delegate.generateLocation method. Set your AppDelegate.mappedInDelegate property to an instance of your custom class instead of the default MappedIn.Delegate class

*v0.7.0*

* You can check if a MapViewMarker is already part of a MapView with mapview.hasMarker(marker), and adding a marker that's true of will no longer cause a crash.


*v0.6.0*

* Added focusOn for arrays of Polygons
* Camera panning tracks fingers in orthographic and perspective mode
* focusScaleZoom = 1.0 should be the tightest zoom possible

*v0.5.0*

* Implemented animated paths
* The `elevation` property on the MapView.Path class has been removed. The Path will now stick to `z=0`
* The MapView.Path class has gained a `height` property specifying the height of the path when rendered
* Changed `maxCameraPitch` property to `maxPitch`

*v0.4.0:*

* Added orthographic camera support
* Fixed animation bug
* Fixed polygon logos blocking taps

*v0.3.0*

* Implemented Custom Location Types

*v0.2.0:*

* Update to Swift 2.2
* Rename Node to Coordinate
* Replace MapAnchor with Coordinates
* Coordinates gain the ability to be created from a Polygon (for MapAnchor support) and CLLocationCoordinate2D (latitude/longitude)
* Exposed the SCNView on the MapView
* A lot of under the hood work on georeferencing Map's

## Roadmap
*Short Term:*

* Map loading time improvements
* MapView refactor and API cleanup
* Venue loading time improvements
* Mappedin Events API
* Directions improvements

*Long Term:*

* Offline data caching
* Geolocation based Venue prefetching
* Indoor Positioning

## Setup
1. Start by cloning this repo (or downloading the zip if you don't like git). 
2. Use [Cocoa Pods](https://cocoapods.org/) to install the latest version of the `MappedIn.framework`
   * The sample repo contains an example `.podfile` configured to install the framework.
3. Open the included Workspace in XCode. 
4. Build the Example project
5. Open info.plist and input your MappedInUsername and MappedInPassword. If you don't know what those are, talk to your MappedIn representative.
6. Run!

## API Quick Start
You can view all the documentation in this project's [GitHub Page](http://mappedin.github.io/ios/), but here's a quick start guide to just displaying a Map.

Let's go through the key classes provided by the SDK and when you would use them.

### MappedIn
This is the class to start with. It controls all communication with the MappedIn API. Make sure you have your API key and Secret set in your .plist file, and then call 

```MappedIn.getVenues(callBack: (venue: [Venue]) -> Void)```

This will query the MappedIn servers and execute the `callBack` function you provided with a list of `Venue`s your key has access to. Each `Venue` will have basic details like the name and logo populated, but not the larger fields like `maps` and `locations`.

To get all of the data for a specific venue, call

```MappedIn.getVenue(venue: Venue, callBack: (Venue) -> Void)```

Similar to `getVenues`, this function will interface with the MappedIn API for you, sending the fully populated `Venue` to your callback when it's done.

### Venue
The `Venue` object will contain all information associated with a given venue (once it's been filled in with `getVenue`).

### MapView
The `MapView` class will display your your map for you/ Once you have a populated venue, set the `.venue` property on your `MapView` and call `yourMapView.loadScene()`

That's the basics. Directions, Markers and other features will be covered in a future tutorial, but you can see them in action right now in the Single Venue project.
