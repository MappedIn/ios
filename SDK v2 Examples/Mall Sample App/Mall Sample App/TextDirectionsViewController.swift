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

    // assign label to instructions or programmatically add labels
    var instructions: [MiInstruction]?
    @IBOutlet weak var instructionsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let listInstructions = self.instructions {
            // create labels for instructions
            for _ in listInstructions {
                print()
            }
        } else {
            // create label to say that you're at your destination
        }
    }
    @IBAction func closeTextDirections(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
