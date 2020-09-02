//
//  ActionPromptView.swift
//  Example
//
//  Created by Christine Maiolo on 2019-06-03.
//  Copyright © 2019 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

class ActionPromptView: UIView {
    @IBOutlet weak var actionPromptIcon: UIImageView!
    @IBOutlet weak var actionPromptMessage: UILabel!

    static func initFromNib() -> ActionPromptView {
        return UINib(nibName: "ActionPromptView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! ActionPromptView
    }
}
