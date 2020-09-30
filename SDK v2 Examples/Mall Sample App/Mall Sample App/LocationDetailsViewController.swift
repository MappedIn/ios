//
//  LocationDetailsViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

class LocationDetailsViewController: UIViewController {
    var location: MiLocation?
    
    
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var locationLogo: UIImageView!
    @IBOutlet weak var locationDescription: UILabel!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var generalInfoContainer: UIView!
    
    override func viewDidLoad() {
    
        updateDetails()
        super.viewDidLoad()
    }
    
    func updateDetails() {
        generalInfoContainer.layer.borderWidth = 1
        generalInfoContainer.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        if let _location = location {
            locationTitle.text = _location.name
            logoView.layer.borderWidth = 1
            logoView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
            if let logoUrl = _location.logo?.medium {
                let url = URL(string: logoUrl)
                locationLogo.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, URL) in
                    self.view.setNeedsLayout()
                })
            }
        }
        
//        locationDescription.text = location?.categories.description
//        locationAddress.text = location.
//        locationContactInfo.text = location.
    }
}

