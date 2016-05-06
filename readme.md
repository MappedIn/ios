# MappedIn iOS SDK Example

This repo contains a simple example to get you started with the MappedIn iOS SDK. Before you can do anything, make sure you have an API key from MappedIn. Talk to your representative to get one.

## Changes
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

* Basic Analytics (basically just logging information so we can get a sense of SDK version usage in the real world)
* Major coordinate system and MapView refactoring
* Venue-wide coordinate system removing the need for Coordinate's to belong to specific Map's
* Lock down the MapView API for 1.0 release
* MappedIn Events API
* Directions improvements

*Long Term:*

* Offline data caching
* Geolocation based Venue prefetching
* Analytics
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
