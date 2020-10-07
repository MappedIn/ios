//
//  InstructionTableViewCell.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-10-01.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit

class InstructionTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let viewWidth = contentView.frame.size.width
        let viewHeight = contentView.frame.size.height
        self.imageView?.frame = CGRect(x: 320, y: 30, width: viewHeight-50, height: viewHeight-50)
        self.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        self.textLabel?.frame = CGRect(x: 28, y: 5, width: viewWidth-100, height: viewHeight-10)
        self.detailTextLabel?.frame = CGRect(x: 28, y: 40, width: viewWidth-100, height: viewHeight-10)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView?.kf.cancelDownloadTask()
        self.imageView?.kf.setImage(with: URL(string: ""))
        self.imageView?.image = nil
    }
    
}
