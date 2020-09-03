//
//  VenueSelectorView.swift
//  Example
//
//  Created by Thomas Cheng on 2019-06-17.
//  Copyright © 2019 Mappedin. All rights reserved.
//

import Foundation
import Mappedin
import UIKit

class VenueSelectorView: UIView {
    static func initFromNib() -> VenueSelectorView {
        return UINib(nibName: "VenueSelectorView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! VenueSelectorView
    }
    
    @IBOutlet weak var venueTableView: UITableView! {
        didSet {
            self.venueTableView.delegate = (self as UITableViewDelegate)
            self.venueTableView.dataSource = (self as UITableViewDataSource)
            let nib = UINib(nibName: "VenueSelectorCell", bundle: nil)
            self.venueTableView.register(nib, forCellReuseIdentifier: "VenueSelectorCell")
        }
    }
    
    private var venueArray = [String]()
    private var venueDictionary: Dictionary = [String: Int]()
    
    var onVenueSelected: VenueSelectorCell?
    
    func setVenues(venueListings: [VenueListing]) {
        let venueListings = venueListings.sorted(by: {venue1, venue2 in
            return venue1.name.localizedStandardCompare(venue2.name) == .orderedAscending ? true : false
        })
        
        self.venueArray = [String]()
        var indexPaths = [IndexPath]()
        for index in 0..<venueListings.count {
            self.venueArray.append(venueListings[index].name)
            indexPaths.append(IndexPath(row: index, section: 0))
            if let venueName = self.venueArray.last {
                self.venueDictionary[venueName] = index
            }
        }
        self.venueTableView.register(VenueSelectorCell.self, forCellReuseIdentifier: "VenueSelectorCell")
        self.venueTableView.dataSource = self
        self.venueTableView.insertRows(at: indexPaths, with: .automatic)
    }
    
    func highlightTableViewCell(venueName: String) {
        guard let rowIndex = venueDictionary[venueName] else { return }
        let index = IndexPath(row: rowIndex, section: 0)
        self.venueTableView.selectRow(at: index as IndexPath, animated: true, scrollPosition: .middle)
    }
    
    typealias VenueSelected = (String) -> ()
    var newVenueSelected: VenueSelected?
}

extension VenueSelectorView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venueArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = venueTableView.dequeueReusableCell(withIdentifier: "VenueSelectorCell", for: indexPath) as! VenueSelectorCell
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = self.venueArray[indexPath.row]
        cell.textLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 16)
        let selectedView = UIView()
        selectedView.backgroundColor = Colors.searchBarColor
        cell.selectedBackgroundView = selectedView
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension VenueSelectorView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        newVenueSelected?(self.venueArray[indexPath.row])
    }
}

class VenueSelectorCell: UITableViewCell {}
