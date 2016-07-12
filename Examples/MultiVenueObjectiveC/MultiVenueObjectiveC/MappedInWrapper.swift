//
//  MappedInWrapper.swift
//  MultiVenueObjectiveC
//
//  Created by Zachary Cregan on 2016-07-12.
//  Copyright © 2016 Zachary Cregan. All rights reserved.
//

import Foundation
import MappedIn

@objc
public class MappedInWrapper: NSObject {
    private static var venues = [Venue]()
    private static var venue: Venue?
    
    public static func getVenues(callback: ([String] -> Void)) {
        MappedIn.getVenues({venues in
            MappedInWrapper.venues = venues
            let venueNames = venues
                .map({venue in
                    return venue.name
                })
            
            callback(venueNames)
        })
    }
    
    public static func getVenue(name: String, callback: ([String] -> Void)) {
        if let matchedVenue = MappedInWrapper.venues.filter({venue in
            return venue.name == name
        }).first {
            MappedIn.getVenue(matchedVenue, callback: {venue in
                MappedInWrapper.venue = venue
                let locationNames = venue.locations
                    .map({location in
                        return location.name
                    })
                
                callback(locationNames)
            })
        }
    }
}