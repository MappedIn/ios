# Mappedin iOS Integrations

In this repo you can find a number of sample applications demonstrating different ways to integrate with Mappedin to render your maps and begin building your own custom indoor mapping experiences on iOS. To learn more about ways to integrate with Mappedin, checkout [developer.mappedin.com](https://developer.mappedin.com/).

The Mappedin SDK for iOS enables you to build powerful, highly flexible, unique, indoor mapping experiences natively inside your iOS apps. This repo contains projects showcasing versions 1 and 2 of our fully native SDK, with more projects coming soon to get you started on more advanced projects. 

This repo also contains a project demonstrating how to integrate with our our out of the box web product, [Mappedin Web](https://www.mappedin.com/wayfinding/web-app/), within a webview on a mobile app. 

## Mappedin iOS SDK v2 Examples

We're very excited to launch version 2 of The Mappedin SDK for iOS! Version 2 is a completely new SDK built from the ground up to enable us to take indoor mapping experiences further than ever before. The SDK supports much of the sample functionality as version 1 and more, but in version 2, rendering is powered by the [Mapbox Maps SDK](https://docs.mapbox.com/ios/maps/examples/). This means that you'll be able to use some features of the Mapbox Maps SDK as well as Mappedin features.

You can view all the [documentation](https://developer.mappedin.com/docs/ios/) for the SDK along with informative [guides](https://developer.mappedin.com/guides/ios/) at [developer.mappedin.com](https://developer.mappedin.com/).

In this repo we've provided some sample code to get you started on the SDK, and we've also provided a key and secret for the SDK that has access to some demo venues. When you're ready to start using your own venues with the SDK you will need to contact a Mappedin representative to get your own unique key and secret.

### Quickstart

This is simple walkthrough to get you started with the Mappedin iOS SDK as quickly as possible, with minimal code. What you'll see is a map rendered on the screen for you to manipulate with familiar guestures, but no other interactions are enabled. The Mappedin iOS SDK provides many ways to interact with the MapView and map data, but as this sample demonstrates, there is no built-in UI or default map interactions. You have complete flexibility over the behaviour, look and feel of applications built using the SDK.

Use this sample to start off if you want to integrate with the Mappedin iOS SDK from scratch. More samples will be coming soon to demonstrate how to interact with the map in differnet ways to build sophisticated experiences. 

## Mappedin iOS SDK v1 Examples

You can view all the up to date documentation in this project's [GitHub Page](http://mappedin.github.io/ios/).

We've provided a key and secret in this repo that has access to some demo venues.

When you're ready to start using your own venues with the SDK you will need to contact a Mappedin representative to get your own unique key and secret.

### Walkthrough

This is simple walkthrough to get you started with the MappedIn iOS SDK, with minimal code, and lots of helpful comments. The Mappedin iOS SDK provides many ways to interact with the MapView and map data, but as this sample demonstrates, there is no built-in UI or default map interactions. You have complete flexibility over the behaviour, look and feel of applications built using the SDK.

Use this sample to start off if you want to integrate with the Mappedin iOS SDK from scratch. Take a look at the next sample in this repo for sample code on how to use a few of the key features the SDK provides.

### Wayfinding Demo

This is a fully featured sample app. It is integrated with Apple's location service. We've provided keys with access to a few venues including a fake mall called "Mappedin Demo Mall." We've also included a GPX file called Location.gpx that simulates a user moving around this venue.

If you want to try out the blue dot functionality, you will need to **Edit Scheme**, **Allow Location Simulation**, and select this **Location** as **Default Location**. Right now it is set up to simulate user walking around mappedin-demo-mall. Modify the coordinates in this file if you wish to simulate a different location

## Web Examples

### Mappedin Web Example

This is a short demonstration of creating a Web View in an iOS application, and displaying Mappedin Web. It also contains an example of setting up external links to open in a separate browser.

To get you started we've provided a Mappedin Web API key and secret that has access to some demo venues.

When you're ready to start using your own venues you will need to contact a Mappedin representative to get your own unique key and secret. Add your Mappedin API keys, search keys, and the venue's slug to this file.
