//
//  extensions.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-16.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Foundation
import Mappedin

extension ImageSet {
    func load(_ size: Int, loaded: @escaping (UIImage) -> ()) {
        let url = self[size]
        print("load url: \(url)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Could not load \(url) error: \(error)")
                return
            }
            
            if let r = response as? HTTPURLResponse, r.statusCode != 200 {
                print("Did not get 200 status code")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    loaded(image)
                }
            } else {
                print("icon did not get loaded")
            }
        }
        task.resume()
    }
}

extension Navigatable {
    func name() -> String {
        switch self {
        case is Coordinate:
            return "My Location"
        case let polygon as Polygon:
            return polygon.locations.first!.name
        case let location as Location:
            return location.name
        default:
            return "unknown"
        }
    }
    
    func getMap() -> Map? {
        switch self {
        case let coord as Coordinate:
            return coord.map
        case let polygon as Polygon:
            return polygon.map
        case let location as Location:
            return location.polygons.makeIterator().next()?.map
        default:
            return nil
        }
    }

    func getDirections(to destination: Navigatable, accessible: Bool) -> Directions? {
        switch self {
        case let coord as Coordinate:
            return destination.directions(from: coord, accessible: accessible)
        case let polygon as Polygon:
            return destination.directions(from: polygon, accessible: accessible)
        case let location as Location:
            return destination.directions(from: location, accessible: accessible)
        default:
            return nil
        }
    }
}


