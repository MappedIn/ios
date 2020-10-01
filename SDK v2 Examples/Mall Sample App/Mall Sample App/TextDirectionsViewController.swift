//
//  TextDirectionsViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-10-01.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

class TextDirectionsViewController: UIViewController {

    
    // give cancel button actions
    // assign label to instructions or programmatically add labels
    var instructions: [MiInstruction]!
    @IBOutlet weak var textDirections: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for _ in instructions {
            print()
        }

    }
}
