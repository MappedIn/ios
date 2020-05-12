//
//  StoreInfoView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-08.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin

private func createCategoryLabel(category: String, x: CGFloat) -> UILabel {
    let label: RoundLabel = RoundLabel(frame: CGRect(x: x, y: 0.0, width: 100, height: 32))
    label.backgroundColor = Colors.azure
    label.cornerRadius = 10
    label.text = category
    label.textColor = UIColor.white
    label.sizeToFit()
    label.textAlignment = .center
    label.frame.size.width += 20
    return label
}

class StoreInfoView: UIView {
    static func initFromNib() -> StoreInfoView {
        return UINib(nibName: "StoreInfoView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! StoreInfoView
    }

    @IBOutlet weak var storeImage: UIImageView!
    @IBOutlet weak var storeName: UILabel!
    @IBOutlet weak var buttonPhone: RoundButton!
    @IBOutlet weak var buttonWebsite: RoundButton!
    @IBOutlet weak var buttonDirections: RoundButton!
    @IBOutlet weak var storeCatagories: UIScrollView!
    
    var store: Navigatable? {
        didSet {
            guard let store = self.store else {
                return
            }
            storeName.text = store.name()
//            var x: CGFloat = 0
//            for catagory in store.categories {
//                let label = createCategoryLabel(category: catagory.name, x: x)
//                self.storeCatagories.addSubview(label)
//                x += 8 + label.frame.width
//            }
        }
    }
    
    typealias locationCallback = (Location) -> ()
    var onSelected: locationCallback?
    
    typealias SimpleAction = () -> ()

    var directionButtonPressed: SimpleAction?
    @IBAction func directionsButtonPressed(_ sender: Any) {
        directionButtonPressed?()
    }
    
}
