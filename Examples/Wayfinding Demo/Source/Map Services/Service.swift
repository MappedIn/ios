//
//  Service.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-09.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Mappedin

struct Service: Mappedin.Service {
    // First you must specify if you are using a custom `Venue` type, This is normal
    // and required for almost all of our customers.
    typealias VenueType = Venue
    let venueType = Venue.self
    
    //In order to use the Mappedin iOS SDK you will need an API Key and Secret.
    // To get you started we've provided a key and secret in this repo that has
    // access to some demo venues.
    //
    // When you're ready to start using your own venues with the Mappedin iOS SDK
    // you will need to contact a Mappedin representative to get your own unique
    // key and secret.
    //
    // The keys and other secret data are pinned to your app here
    // this will be used when doing any API requests to the Mappedin servers

    let apiKey = "5eb0412d91b055001a68e999"
    let apiSecret = "rvJ4gYNYV3GSePUO5FUNtU9EBBMJAlHq9dBBkZcot1GCtZUr"
    let dataKey = "d5b94aa0"
    let searchUser = "theBiutawieneugai2ongoowu3meipai"
    let searchKey = "ahte1Ei7ieXoh6ra"
    
    // not needed, just done to make sure you set the above values.
    init() {
        assert(apiKey != "", """
            It looks like you are using the SDK without an api key. \
            Please go to the `Service` sturcture and specifiy a key \
            secret and a data key. If you do not know this information \
            please contact your Mappedin to get access to our API.
            """
        )
    }
    
}
