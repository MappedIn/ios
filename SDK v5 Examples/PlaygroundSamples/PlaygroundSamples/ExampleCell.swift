//
//  ExampleCell.swift
//  PlaygroundSamples
//

import UIKit

class ExampleCell: UITableViewCell {
    public static let identifier = "ExampleCell"
    let titleLabel = UILabel()
    let descLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        descLabel.font = .systemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame = CGRect(x: 4, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height / 2)
        descLabel.frame = CGRect(x: 4, y: titleLabel.frame.size.height, width: contentView.frame.size.width, height: contentView.frame.size.height / 2)
    }
}
