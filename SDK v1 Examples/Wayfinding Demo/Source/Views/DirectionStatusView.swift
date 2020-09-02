//
//  DirectionStatusView
//  Example
//
//  Created by Coraline Sherratt on 2018-02-07.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import Mappedin
import UIKit

// average speed of a person can walk in a minute
private let metersAMinute: Float = 1.38889 * 60



class DirectionStatusView: UIView {
    @IBOutlet weak var closeButton: UIButton!

    typealias CloseAction =  () -> ()
    var closeAction: CloseAction?
    
    
    @IBAction func closeDirection(_ sender: Any) {
        self.closeAction?()
    }
    
    static func initFromNib() -> DirectionStatusView {
        return UINib(nibName: "DirectionStatusView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! DirectionStatusView
    }

    var navigation: NavigationState? {
        didSet {
            if let navigation = navigation {
                let distance = navigation.directions.distance
                let time = max(distance / metersAMinute, 1)
                
//                if let turn = navigation.directions.instructions.last?.action as? Directions.Instruction.Turn  {
//                    switch turn.relativeBearing {
//                    case .left, .slightLeft:
//                        line.append(NSAttributedString(
//                            string: " destination will be on the left"
//                        ))
//                    case .right, .slightRight:
//                        line.append(NSAttributedString(
//                            string: " destination will be on the right"
//                        ))
//                    default:
//                        line.append(NSAttributedString(
//                            string: " destination will be ahead"
//                        ))
//                    }
//                }
                self.info.text = navigation.to.name()
                self.timeInfo.text = String(format: "%.0fmin", time)
                self.distanceInfo.text = String(format: "%.0fM", distance)
                /*(navigation.to.locations.first as? Venue.Tenant)?.logo?.load(64) { image in
                    self.icon.image = image
                }*/
            }
        }
    }

    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var timeInfo: UILabel!
    @IBOutlet weak var distanceInfo: UILabel!
    @IBOutlet weak var icon: RoundImageView!
}


