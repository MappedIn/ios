//
//  PathSelectView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-27.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import Mappedin

fileprivate extension Navigatable {
     func name() -> String? {
        switch self {
        case let polygon as Polygon:
            return polygon.locations.first?.name()
        case let location as Location:
            return location.name
        default:
            return nil
        }
    }
}


class PathSelectView: UIView {
    //@IBOutlet weak var fromSearchBar: UISearchBar!
    @IBOutlet weak var toSearchBar: UISearchBar!
    //@IBOutlet weak var swapButton: UIButton!

    var state: PathSelectState? = nil {
        didSet {
            self.toSearchBar.text = state?.to.name()
        }
    }

    static func initFromNib() -> PathSelectView {
        return UINib(nibName: "PathSelectView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! PathSelectView
    }
    
}
