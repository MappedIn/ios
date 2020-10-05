//
//  LocationViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-29.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import Kingfisher

class LocationViewController: UITableViewController, UISearchBarDelegate {
    
    var categories: [MiCategory] = []
    var filteredCategories: [MiCategory] = []
    var navLocation: NavigationLocation = .start
    var navDelegate: NavigationDelegate? = nil
    @IBOutlet weak var locationSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset.left = 10
        locationSearchBar.delegate = self
        filteredCategories = filterCategories(searchText: locationSearchBar.text ?? "")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return filteredCategories.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCategories[section].locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let location = filteredCategories[indexPath.section].locations[indexPath.row]
        cell.textLabel?.text = location.name
        if let logoUrl = location.logo?.xxsmall {
            let url = URL(string: logoUrl)
            cell.imageView?.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, URL) in
                cell.setNeedsLayout()
            })
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredCategories[section].name
    }

    func filterCategories(searchText: String) -> [MiCategory] {
        var filteredCategories: [MiCategory] = []
        if searchText.count > 0 {
            for category in categories {
                let filteredLocations = category.locations.filter{ $0.name.range(of: searchText, options: .caseInsensitive) != nil }
                if !filteredLocations.isEmpty {
                    let newCategory = MiCategory(id: category.id, name: category.name, picture: category.picture)
                    newCategory.locations = filteredLocations
                    filteredCategories.append(newCategory)
                }
            }
            return filteredCategories
        }
        return categories
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCategories = filterCategories(searchText: searchText)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navDelegate?.onLocationUpdate(navigationLocation: navLocation, location: filteredCategories[indexPath.section].locations[indexPath.row])
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
}

