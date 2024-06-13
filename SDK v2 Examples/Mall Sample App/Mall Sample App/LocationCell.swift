//
//  LocationCell.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import Foundation
import UIKit

class LocationCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let viewWidth = contentView.frame.size.width
        let viewHeight = contentView.frame.size.height
        self.imageView?.frame = CGRect(x: 10,y: 5, width: viewHeight-10, height: viewHeight-10)
        self.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        self.textLabel?.frame = CGRect(x: 55, y: 5, width: viewWidth-60, height: viewHeight-10)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView?.kf.cancelDownloadTask()
        self.imageView?.kf.setImage(with: URL(string: ""))
        self.imageView?.image = nil
    }
    
}
