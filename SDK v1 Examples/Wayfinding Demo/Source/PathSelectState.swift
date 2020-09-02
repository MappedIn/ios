//
//  PathSelectState.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-28.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import Mappedin

struct PathSelectState {
    var from: Navigatable
    var to: Navigatable
    var directions: Directions
    var accessible: Bool
    var map: Map
    
    init?(from: Coordinate, to: Navigatable, accessible: Bool) {
        if let directions = from.getDirections(to: to, accessible: accessible) {
            self.directions = directions
        } else {
            return nil
        }
        
        if directions.distance > 1000 {
            return nil
        }
        
        self.to = to
        self.from = from
        self.accessible = accessible
        self.map = directions.path[0].map
    }
}
