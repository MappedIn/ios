// UIColor+Hex.swift
//
// Extension to create UIColor instances from hex color strings.
//
// The MVF v3 default-style.json file specifies colors as hex strings
// (e.g. "#e0e0e0"). This extension converts those strings to UIColor
// objects for use with MapKit overlay renderers.

import UIKit

extension UIColor {

    /// Creates a UIColor from a hex color string.
    ///
    /// Supports the following formats:
    /// - "#RRGGBB" (e.g. "#e0e0e0")
    /// - "RRGGBB" (e.g. "e0e0e0")
    /// - "0xRRGGBB" (e.g. "0xe0e0e0")
    ///
    /// - Parameter hex: A hex color string.
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        } else if hexString.hasPrefix("0X") {
            hexString.removeSubrange(
                hexString.startIndex..<hexString.index(hexString.startIndex, offsetBy: 2))
        }

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
