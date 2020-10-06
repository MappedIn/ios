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
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var generalInfoContainer: UIView!
    @IBOutlet weak var locationCategory: UILabel!
    @IBOutlet weak var locationContact: UILabel!
    @IBOutlet weak var locationAddress: UILabel!
    
    override func viewDidLoad() {
        updateDetails()
        super.viewDidLoad()
    }
    
    func updateDetails() {
        
        // Add border styles to view containing store name and logo
        generalInfoContainer.layer.borderWidth = 1
        generalInfoContainer.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        
        if let _location = location {
            
            // insert location data into locationDetailsView labels: Store Name, Store Logo, Store Category,
            // Store Address and Store Phone Number
            locationTitle.text = _location.name
            logoView.layer.borderWidth = 1
            logoView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
            if let logoUrl = _location.logo?.medium {
                let url = URL(string: logoUrl)
                locationLogo.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, URL) in
                    self.view.setNeedsLayout()
                })
            }
            locationCategory.text = _location.categories.description
            locationAddress.text = _location.address
            locationContact.text = _location.phoneNumber
            
        }
    }
}

