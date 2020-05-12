//
//  RoundUI.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-16.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class RoundView: UIView {
    private func setMask() {
        switch (roundTop, roundBottom) {
        case (true, true):
            if #available(iOS 11.0, *) {
                layer.maskedCorners = [
                    .layerMaxXMaxYCorner,
                    .layerMinXMaxYCorner,
                    .layerMaxXMinYCorner,
                    .layerMinXMinYCorner
                ]
            } else {
                // Fallback on earlier versions
            }
        case (true, false):
            if #available(iOS 11.0, *) {
                layer.maskedCorners = [
                    .layerMaxXMinYCorner,
                    .layerMinXMinYCorner
                ]
            } else {
                // Fallback on earlier versions
            }
        case (false, true):
            if #available(iOS 11.0, *) {
                layer.maskedCorners = [
                    .layerMaxXMaxYCorner,
                    .layerMinXMaxYCorner,
                ]
            } else {
                // Fallback on earlier versions
            }
        case (false, false):
            if #available(iOS 11.0, *) {
                layer.maskedCorners = []
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @IBInspectable var roundTop: Bool = true {
        didSet {
            setMask()
        }
    }

    @IBInspectable var roundBottom: Bool = true {
        didSet {
            setMask()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}

@IBDesignable
class RoundImageView: UIImageView {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}

@IBDesignable
class RoundButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}

@IBDesignable
class RoundLabel: UILabel{
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
}

