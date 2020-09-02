//
//  Venue.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-09.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Mappedin

// The 1st class you will need to define is a `Venue` class. A `Venue` holds one or more
// maps and all the associated data that is needed for searching / direction wayfinding.
//
// The Venue will include custom deserialization that is supplied by Mappedin. This code
// is ridged and is best if you avoid touching it.

class Venue: Mappedin.Venue {
    
    // custom types can be added by our backend servers

    var tenants = [Tenant]()
    
    required init(inflate venueListing: VenueListing,
                  with buffer: inout BinaryDecoder) throws
    {
        try super.init(inflate: venueListing, with: &buffer)
        tenants = try buffer.pullValue()
        self.tenants.forEach { self.locations.append($0) }
    
    }
    
    class Tenant: Mappedin.Location {
        var id: String = ""

        required init(from buffer: inout BinaryDecoder) throws {
            try super.init(from: &buffer)
            self.id = try buffer.pullValue()
        }
    }

    /*
     Example of a location with many properties. Location types must have
     properties that match those specified in the dataKey, or a deserialization 
     error will occur

     class Tenant: Mappedin.Location {
        var id: String = ""
        var externalId: String = ""
        var description: String = ""
        var logo: ImageSet? = nil
        var phone: PhoneNumber? = nil

        required init(from buffer: inout BinaryDecoder) throws {
            try super.init(from: &buffer)
            self.id = try buffer.pullValue()
            self.externalId = try buffer.pullValue()
            self.description = try buffer.pullValue()
            self.logo = try buffer.pull(ImageSet?.self)
            self.phone = try buffer.pull(PhoneNumber?.self)
        }
    }*/

}
