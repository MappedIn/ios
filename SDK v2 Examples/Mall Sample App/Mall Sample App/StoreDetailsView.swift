//
//  StoreDetailsView.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

@objc protocol StoreDetailsDelegate: class {
    func didTapGetDirections()
    func didTapViewDetails()
}

class StoreDetailsView : UIView {
    let nibName = "StoreDetailsView"
    var delegate: StoreDetailsDelegate!
    var contentView: UIView?
    var location: MiLocation? {
        didSet {
            updateDetails()
        }
    }
    
    @IBAction func GetDirections(_ sender: Any) {
        self.delegate.didTapGetDirections()
    }
    
    @IBAction func ViewDetails(_ sender: Any) {
         self.delegate.didTapViewDetails()
    }
    
    
    @IBOutlet weak var ViewDetails: UIButton!
    @IBOutlet weak var GetDirections: UIButton!
    @IBOutlet weak var storeImage: UIImageView!
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var storeLevel: UILabel!
    @IBOutlet weak var logoView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
    }
    
    
    func updateDetails() {
        // TODO: if logo url is nil, set to blank image
        if let _location = location {
            storeName.text = _location.name
            logoView.layer.borderWidth = 1
            logoView.layer.borderColor = UIColor.lightGray.cgColor
            if let logoUrl = _location.logo?.medium {
                let url = URL(string: logoUrl)
                storeImage.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, URL) in
                    self.setNeedsLayout()
                })
            } else {
                storeImage.image = nil
            }
            
            if let level = _location.spaces.first?.level {
                storeLevel.text = level.name
            }
        }
    }

    
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
}

