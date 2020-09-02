//
//  Colors.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-16.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Foundation
import UIKit

struct Colors {
    static let userIcon = UIColor.blue
    static let pathColor = UIColor.orange
    static let black = UIColor(red: 41/255, green: 41/255, blue: 35/255, alpha: 1)
    static let azure = UIColor(red: 0, green: 149/255, blue: 230/255, alpha: 1)
    static let lightAzure = UIColor(red: 40/255, green: 165/255, blue: 232/255, alpha: 1)
    static let green = UIColor(red: 55/255, green: 96/255, blue: 61/255, alpha: 1)
    static let white = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
    static let searchBarColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08)
    static let remainingPath = UIColor(red: 0.175, green: 0.175, blue: 0.5, alpha: 1)
    static let travelledPath = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    static let destinationPolygon = Colors.azure
    static let sourcePolygon = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}
