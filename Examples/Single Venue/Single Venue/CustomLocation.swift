//
//  CustomLocation.swift
//  Single Venue
//
//  Created by Paul Bernhardt on 2016-04-12.
//  Copyright © 2016 MappedIn. All rights reserved.
//

import Foundation
import MappedIn

class CustomLocation: Location {
    let description: String?
    let logo: ImageCollection?
    
    override init?(_ data: RawData) {
        self.description = data["description"].stringValue()
        self.logo = data["logo"].imageCollection()
        super.init(data)
    }
}