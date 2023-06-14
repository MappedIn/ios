//
//  NavigationDelegate.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import Foundation
import Mappedin

protocol NavigationDelegate {
    func onLocationUpdate(navigationLocation: NavigationLocation, location: MiLocation?)
}

enum NavigationLocation {
    case start
    case end
}
