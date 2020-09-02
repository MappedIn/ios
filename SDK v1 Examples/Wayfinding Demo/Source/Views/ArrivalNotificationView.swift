//
//  ArrivalNotificationView.swift
//  Example
//
//  Created by Christie Felker on 2019-05-27.
//  Copyright © 2019 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin

public class ArrivalNotificationView: UIView {
    @IBOutlet weak var arrivedIcon: UIImageView!
    @IBOutlet weak var arrivedLabel: UILabel!
    
    static func initFromNib() -> ArrivalNotificationView {
        return UINib(nibName: "ArrivalNotificationView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! ArrivalNotificationView
    }
}
