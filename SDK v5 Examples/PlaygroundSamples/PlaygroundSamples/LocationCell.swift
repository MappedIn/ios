//
//  LocationCell.swift
//  PlaygroundSamples
//

import UIKit

class LocationCell: UITableViewCell {
    public static let identifier = "LocationCell"
    var logoImage = UIImageView()
    let nameLabel = UILabel()
    let descLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(logoImage)
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        logoImage.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        logoImage.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        logoImage.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        logoImage.heightAnchor.constraint(equalToConstant: 64).isActive = true
        logoImage.widthAnchor.constraint(equalToConstant: 64).isActive = true
        logoImage.contentMode = .scaleAspectFit
        
        
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leadingAnchor.constraint(equalTo: logoImage.layoutMarginsGuide.trailingAnchor, constant: 24).isActive = true
        nameLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        nameLabel.font = .systemFont(ofSize: 18)
        nameLabel.numberOfLines = 0

        contentView.addSubview(descLabel)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.leadingAnchor.constraint(equalTo: logoImage.layoutMarginsGuide.trailingAnchor, constant: 24).isActive = true
        descLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        descLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.numberOfLines = 3
        descLabel.lineBreakMode = .byTruncatingTail
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImageView{
    func load(url: URL) {
          DispatchQueue.global().async { [weak self] in
             if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                  DispatchQueue.main.async {
                    self?.image = image
                  }
                }
             }
          }
       }
}
