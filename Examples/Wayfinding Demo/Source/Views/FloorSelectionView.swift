//
//  FloorSelectionView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-13.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin

class FloorSelectionView: UIView {
    static func initFromNib() -> FloorSelectionView {
        return UINib(nibName: "FloorSelectionView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! FloorSelectionView
    }
    
    @IBOutlet weak var floorTableView: UITableView!{
        didSet {
            self.floorTableView.delegate = (self as UITableViewDelegate)
            self.floorTableView.dataSource = (self as UITableViewDataSource)
            let nib = UINib(nibName: "FloorSelectionCell", bundle: nil)
            self.floorTableView.register(nib, forCellReuseIdentifier: "FloorSelectionCell")
        }
    }
    
    @IBOutlet weak var floorShortHandLabel: UITextView!
    @IBOutlet weak var floorNavigationButton: UIButton!
    
    @IBOutlet weak var floorLabelSelectorWidth: NSLayoutConstraint!
    @IBOutlet weak var floorTableSelectorWidth: NSLayoutConstraint!
    @IBOutlet weak var floorTableSelectorHeight: NSLayoutConstraint!
    
    private var floorLabelWidth: CGFloat = 0.0
    private let floorTableWidth: CGFloat = 170
    private let cornerRadius: CGFloat = 5
    
    private var floorFullName: String?
    private var floorNameCellHeightDictionary = [Int: CGFloat]()
    private var floors = [String]()
    private var floorDictionary: Dictionary = [String:Int]()
    
    var recommendedHeight: CGFloat {
        return min(CGFloat(self.floors.count * 44), CGFloat(220))
    }
    
    typealias MapSelected = (String) -> ()
    var onMapSelected: MapSelected?
    
    func setCurrentFloor(map: Map) {
        self.floorShortHandLabel.text = map.shortName
        self.adjustContentSize(textView: floorShortHandLabel)
        self.setLabelWidth()
        self.floorFullName = map.name
        self.highlightTableViewCell(map: map)
    }
    
    func setVenueMaps(maps: [Map]) {
        let maps = maps.sorted(by: { $0.floor > $1.floor})
        self.floors = [String]()
        if self.floorDictionary.count > 0 {
            self.floorDictionary.removeAll()
        }
        for index in 0..<maps.count {
            self.floors.append(maps[index].name)
            self.floorDictionary[maps[index].name] = index
        }
        self.setup()
    }
    
    func getFloorLabelWidth() -> CGFloat {
        return self.floorLabelWidth
    }
    
    func collapseLevelSelector() {
        self.floorNavigationButton.setImage(UIImage(named: "Backward"), for: .normal)
        self.floorShortHandLabel.isHidden = false
        self.floorTableView.isHidden = true
        self.floorTableSelectorWidth.constant = floorLabelWidth
        self.floorLabelSelectorWidth.constant = floorLabelWidth
        self.isFloorTableDisplayed = false
        onLevelSelectorExpanded?(isFloorTableDisplayed)
    }
    
    typealias LevelSelectorExpanded = (Bool) -> ()
    var onLevelSelectorExpanded: LevelSelectorExpanded?
    
    private func highlightTableViewCell(map: Map) {
        guard let rowIndex = floorDictionary[map.name] else { return }
        let index = IndexPath(row: rowIndex, section: 0)
        self.floorTableView.selectRow(at: index as IndexPath, animated: true, scrollPosition: .middle)
    }
    
    private func highlightTableViewCell(rowIndex: Int) {
        let index = IndexPath(row: rowIndex, section: 0)
        self.floorTableView.selectRow(at: index as IndexPath, animated: true, scrollPosition: .middle)
    }
    
    private func setLabelWidth() {
        self.floorLabelWidth = min(self.floorShortHandLabel.textStorage.size().width + 20, 130)
        self.floorLabelSelectorWidth.constant = self.floorLabelWidth
    }
    
    private func setup() {
        setLabelWidth()
        
        self.floorTableView.register(FloorSelectionCell.self, forCellReuseIdentifier: "FloorSelectionCell")
        self.floorTableView.dataSource = self
        self.floorTableView.reloadData()
        
        if self.floorDictionary.count > 0 && self.floorFullName != nil {
            self.highlightTableViewCell(rowIndex: floorDictionary[self.floorFullName!]!)
        }
        
        self.floorTableSelectorHeight.constant = recommendedHeight
        self.roundSpecifiedCorners(object: floorTableView, radius: cornerRadius, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner])

        self.roundSpecifiedCorners(object: floorShortHandLabel, radius: cornerRadius, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner])
        
        self.floorNavigationButton.backgroundColor = Colors.green
        self.roundSpecifiedCorners(object: floorNavigationButton, radius: cornerRadius, corners: [.layerMinXMinYCorner, .layerMinXMaxYCorner])
        
        self.setNeedsLayout()
    }
    
    private var isFloorTableDisplayed: Bool = false
    @IBAction func floorButtonClick(_ sender: UIButton) {
        if (sender === self.floorNavigationButton && !isFloorTableDisplayed) {
            self.floorNavigationButton.setImage(UIImage(named: "Forwards"), for: .normal)
            self.floorShortHandLabel.isHidden = true
            self.floorTableView.isHidden = false
            self.floorTableSelectorWidth.constant = floorTableWidth
            self.floorLabelSelectorWidth.constant = floorTableWidth
            self.isFloorTableDisplayed = true
            onLevelSelectorExpanded?(isFloorTableDisplayed)
        }
        else if (sender === self.floorNavigationButton && isFloorTableDisplayed){
            self.collapseLevelSelector()
        }
    }
    
    private func adjustContentSize(textView: UITextView) {
        let inset: CGFloat = 3
        textView.contentInset = UIEdgeInsets(top: inset, left: textView.contentInset.left, bottom: inset, right: textView.contentInset.right)
    }
}

extension FloorSelectionView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = floorTableView.dequeueReusableCell(
                withIdentifier: "FloorSelectionCell", for: indexPath
                ) as! FloorSelectionCell
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = self.floors[indexPath.row]
        cell.textLabel?.font = UIFont(name: "AvenirNext", size: 14)
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 0
        let selectedView = UIView()
        selectedView.backgroundColor = Colors.searchBarColor
        cell.selectedBackgroundView = selectedView
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.floors.count
    }
}

extension FloorSelectionView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onMapSelected?(floors[indexPath.row])
        setLabelWidth()
        self.isFloorTableDisplayed = false
        self.floorTableView.isHidden = true
        self.floorTableSelectorWidth.constant = self.floorLabelWidth
        self.floorShortHandLabel.isHidden = false
        self.floorNavigationButton.setImage(UIImage(named: "Backward"), for: .normal)
        onLevelSelectorExpanded?(self.isFloorTableDisplayed)
    }
}

class FloorSelectionCell: UITableViewCell {}
