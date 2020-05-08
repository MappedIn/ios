//
//  ContainerView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-01-24.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit

class ContainerView: UIView {
    public var childView: UIView? = nil {
        willSet(new) {
            childView.map { view in view.removeFromSuperview() }
            new.map { new in self.addSubview(new) }
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        guard let child = childView else { return }
        child.frame.size = self.frame.size
        child.frame.origin.x = 0
        child.frame.origin.y = 0
    }
    
    let requiresConstraintBasedLayout = false
    
}
