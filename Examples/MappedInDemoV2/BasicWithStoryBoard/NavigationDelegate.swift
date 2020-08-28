//
//  NavigationDelegate.swift
//  mapBox-Test
//
//  Created by Danielle Wang on 2020-06-26.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import Foundation
import MappedIn

protocol NavigationDelegate {
    func onLocationUpdate(navigationLocation: NavigationLocation, location: MiLocation?)
}

enum NavigationLocation {
    case start
    case end
}
