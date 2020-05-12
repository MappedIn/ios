//
//  DirectionView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-01-18.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin


public class DirectionView: UIView {
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    
    @IBOutlet weak var directionIcon: UIImageView!
    @IBOutlet weak var directionsIconWidth: NSLayoutConstraint!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var directionsIconLeading: NSLayoutConstraint!

    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!

    var arrivedAtDestination = false
    
    static func initFromNib() -> DirectionView {
        return UINib(nibName: "DirectionView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! DirectionView
    }
    
    public var instruction: Directions.Instruction? = nil {
        didSet {
            updateLabel()
            setImage()
        }
    }
    
    public var distance: Float = 0 {
        didSet {
            updateLabel()
        }
    }
    
    private func updateLabel() {
        if arrivedAtDestination {
            self.directionLabel.text = "You have arrived"
            self.distanceLabel.text = ""
        } else {
            if let instruction = instruction {
                self.directionLabel.text = instruction.description
                self.distanceLabel.text = String(format: "%.0fm ", self.distance)
            } else {
                self.directionLabel.text = "Destination ahead"
                self.distanceLabel.text = String(format: "%.0fm ", self.distance)
            }
        }
        self.adjustDirectionsWidth()
    }
    
    private func adjustDirectionsWidth() {
        // set the labels to a default state
        self.directionLabel.font = self.directionLabel.font.withSize(20)
        self.distanceLabel.font = self.distanceLabel.font.withSize(16)
        self.directionLabel.numberOfLines = 1
        
        // the constant is for frame padding
        let totalFrameWidth = self.directionLabel.frame.width + self.distanceLabel.frame.width - 15
        var totalTextWidth = self.directionLabel.intrinsicContentSize.width + self.distanceLabel.intrinsicContentSize.width
        
        // reduce both the direction font size and distance font size
        // until a certain point
        for _ in 0..<24 {
            if totalTextWidth > totalFrameWidth {
                self.directionLabel.font = self.directionLabel.font.withSize(self.directionLabel.font.pointSize - 0.25)
                self.distanceLabel.font = self.distanceLabel.font.withSize(self.distanceLabel.font.pointSize - 0.15)
                totalTextWidth = self.directionLabel.intrinsicContentSize.width + self.distanceLabel.intrinsicContentSize.width
            } else {
                break
            }
        }
        
        self.directionLabel.preferredMaxLayoutWidth = self.directionLabel.frame.width
        self.directionLabel.numberOfLines = 3
        self.directionLabel.lineBreakMode = .byTruncatingTail
    }
    
    private func setImage() {
        if arrivedAtDestination {
            let icon: UIImage?
            icon = UIImage(named: "Arrived")
            // fix width aspect ratio of the layout.
            if let icon = icon {
                let aspectRatio = icon.size.width / icon.size.height
                directionsIconWidth.constant = aspectRatio * 36
            }
            self.directionsIconLeading.constant = 24
            self.directionIcon.image = icon
        } else {
            if let turn = instruction?.action as? Directions.Instruction.Turn {
                let icon: UIImage?

                switch turn.relativeBearing {
                case .left:
                    icon = UIImage(named: "Direction Left")
                case .slightLeft:
                    icon = UIImage(named: "Direction Slight Left")
                case .straight:
                    icon = UIImage(named: "Direction Straight")
                case .slightRight:
                    icon = UIImage(named: "Direction Slight Right")
                case .right:
                    icon = UIImage(named: "Direction Right")
                }

                // fix width aspect ratio of the layout.
                if let icon = icon {
                    let aspectRatio = icon.size.width / icon.size.height
                    directionsIconWidth.constant = aspectRatio * 36
                }
                self.directionsIconLeading.constant = 12
                self.directionIcon.image = icon
            } else if let connection = instruction?.action as? Directions.Instruction.TakeConnection,
                let instruction = instruction {
                var icon: UIImage?
                if connection.fromMap.floor < connection.toMap.floor {
                    switch instruction.atLocation?.type {
                    case "elevator"?:
                        icon = UIImage(named: "ElevatorUp")
                        break
                    case "escalator"?:
                        icon = UIImage(named: "EscalatorUp")
                        break
                    case "stairs"?:
                        icon = UIImage(named: "StairsUp")
                        break
                    default:
                        icon = UIImage(named: "RampUp")
                        break
                    }
                } else {
                    switch instruction.atLocation?.type {
                    case "elevator"?:
                        icon = UIImage(named: "ElevatorDown")
                        break
                    case "escalator"?:
                        icon = UIImage(named: "EscalatorDown")
                        break
                    case "stairs"?:
                        icon = UIImage(named: "StairsDown")
                        break
                    default:
                        icon = UIImage(named: "RampDown")
                        break
                    }
                }
                if let icon = icon {
                    let aspectRatio = icon.size.width / icon.size.height
                    directionsIconWidth.constant = aspectRatio * 36
                }
                self.directionsIconLeading.constant = 12
                self.directionIcon.image = icon
            } else if let _ = instruction?.action as? Directions.Instruction.ExitConnection {
                let icon = UIImage(named: "Direction Straight")
                // fix width aspect ratio of the layout.
                if let icon = icon {
                    let aspectRatio = icon.size.width / icon.size.height
                    directionsIconWidth.constant = aspectRatio * 36
                }
                self.directionsIconLeading.constant = 12
                self.directionIcon.image = icon
            } else {
                let icon: UIImage?
                icon = UIImage(named: "Arrived")
                // fix width aspect ratio of the layout.
                if let icon = icon {
                    let aspectRatio = icon.size.width / icon.size.height
                    directionsIconWidth.constant = aspectRatio * 36
                }
                self.directionsIconLeading.constant = 24
                self.directionIcon.image = icon
            }
        }
    }
    
    typealias ButtonPress = () -> ()

    var onNextPressed: ButtonPress?
    @IBAction func nextPressed(_ sender: Any) {
        onNextPressed?()
    }
    
    var onPeviousPressed: ButtonPress?
    @IBAction func previousPressed(_ sender: Any) {
        onPeviousPressed?()
    }
    
    var onClose: ButtonPress?
    @IBAction func close(_ sender: Any) {
        onClose?()
    }
}
