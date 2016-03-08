# MappedIn iOS SDK Example

This repo contains a simple example to get you started with the MappedIn iOS SDK. Before you can do anything, make sure you have an API key from MappedIn. Talk to your representative to get one.

## SDK Features
*Current as of v0.1-Alpha5:*

* MapView component to display 3D maps
* Access to localized Venue, Location, Category, Node, Vortex and Polygon data from the MappedIn API
* Full camera control
* User-tappable 2D text and image markers
* Offline directions engine, localized in English and French, pathing to and from any nodes, polygons, or locations
* Path drawing
* Path styling
* Polygon highlighting

*Planned for 1.0 release:*

* Multiple path support
* Expose underlying SceneKit object for advanced use
* User position support
* Path animation

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
