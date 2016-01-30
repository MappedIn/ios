# MappedIn iOS SDK Example

This repo contains a simple example to get you started with the MappedIn iOS SDK. Before you can do anything, make sure you have an API key from MappedIn. Talk to your representative to get one.

## Setup
1. Start by cloning this repo (or downloading the zip if you don't like git). 
2. Open the included Workspace in XCode. 
3. Build the Example project
  * You may notice that before the build, `MappedIn.framework` isn't present, even though it's referenced in the Example project. This is due to a bug in XCode 7 which breaks "fat frameworks" (ie, those that contain files for multiple architectures). We have solved this by providing separate `MappedIn-iphonesimulator.framework` and `MappedIn-iphoneos.framework` files, and the included `framework-swap.sh` script, which runs at the start of the build process and copies the right framework into `MappedIn.framework`. 
  * *Make sure that you include this step in any new MappedIn-enabled projects you create!*
4.  Open info.plist and input your MappedInUsername and MappedInPassword. If you don't know what those are, talk to your MappedIn representative.
5.  Run!

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

That's the basics. Directions and Markers and other features will be covered in a future tutorial.
