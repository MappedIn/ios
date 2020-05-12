//
//  NavigationState.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-12-29.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Foundation
import Mappedin
import UIKit

struct NavigationState {
    var from: Navigatable
    var to: Navigatable
    var directions: Directions
    var index: Int = 0
    var accessible: Bool
    var map: Map
    
    init?(from: Navigatable, to: Navigatable, accessible: Bool) {
        self.from = from
        self.to = to
        self.accessible = accessible
        
        if let directions = from.getDirections(to: to, accessible: accessible) {
            self.directions = directions
        } else {
            return nil
        }
        
        if directions.distance > 1000 {
            return nil
        }
        
        self.map = directions.path[0].map
    }
    
    var isFirst: Bool {
        return index == 0
    }

    var isLast: Bool {
        return index >= directions.instructions.count
    }

    func coordinate(index: Int) -> Coordinate? {
        if index < 0 {
            return self.directions.path.first
        } else if index >= self.directions.instructions.count {
            return self.directions.path.last
        } else {
            return self.directions.instructions[index].coordinate
        }
    }
    
    mutating func updatePositionOnPath(from: Navigatable, to: Navigatable, accessible: Bool) {
        self.from = from
        self.to = to
        self.accessible = accessible
        
        if let directions = from.getDirections(to: to, accessible: accessible) {
            self.directions = directions
        } else {
            return
        }
        
        self.map = directions.path[0].map
    }
    
    var currentFocus: [Focusable] {
        guard let p0 = coordinate(index: index - 1),
              let p1 = coordinate(index: index) else {
            return []
        }
        return [p0, p1]
    }

    var currentHeading: Float {
        guard let p0 = coordinate(index: index - 1),
              let p1 = coordinate(index: index) else {
                return 0
        }
        return p0.vector2.angle(to: p1.vector2)
    }

    var currentDistance: Float {
        if let p0 = coordinate(index: index - 1),
            let p1 = coordinate(index: index) {
            return (p0.vector2 - p1.vector2).length
        }
        else if let p0 = from.navigatableCoordinates.first,
            let p1 = coordinate(index: index) {
            return (p0.vector2 - p1.vector2).length
        } else {
            return 0
        }
    }
    
    var previousInstruction: Directions.Instruction? {
        if isFirst {
            return nil
        } else {
            let prev = index - 1
            if self.directions.instructions.count > prev {
                return self.directions.instructions[prev]
            }
        }
        return nil
    }

    var currentInstruction: Directions.Instruction? {
        if isLast {
            return nil
        }
        return self.directions.instructions[index]
    }
    var nextInstruction: Directions.Instruction? {
        if isLast {
            return nil
        } else {
            let next = index + 1
            if self.directions.instructions.count > next  {
                return self.directions.instructions[next]
            }
        }
        return nil
    }
    
    mutating func setMarker() {
        guard let coordinate = coordinate(index: index) else {
            return
        }
        self.map = coordinate.map
    }
    
    mutating func next() {
        if !isLast {
            self.index += 1
            setMarker()
        }
    }
    
    mutating func previous() {
        if !isFirst {
            self.index -= 1
            setMarker()
        }
    }
}

