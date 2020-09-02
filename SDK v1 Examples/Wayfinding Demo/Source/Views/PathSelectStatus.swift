//
//  PathSelectStatus.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-28.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin

class PathSelectStatus: UIView {
    @IBOutlet weak var storeIcon: RoundImageView!
    @IBOutlet weak var goButton: RoundButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var destination: Navigatable? {
        didSet{
            guard self.destination != nil else {
                return
            }
            descriptionLabel.text = destination!.name()
        }
    }
    
    static func initFromNib() -> PathSelectStatus {
        return UINib(nibName: "PathSelectStatus", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! PathSelectStatus
    }
    
    typealias SimpleAction = () -> ()
    var goButtonPressed: SimpleAction?
    @IBAction func goButtonPressed(_ sender: Any) {
        goButtonPressed?()
    }

}
