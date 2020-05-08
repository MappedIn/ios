//
//  SearchView.swift
//  Example
//
//  Created by Coraline Sherratt on 2018-02-12.
//  Copyright © 2018 Mappedin. All rights reserved.
//

import Foundation
import UIKit
import Mappedin

class SearchView: UIView {
    static func initFromNib() -> SearchView {
        return UINib(nibName: "SearchView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as! SearchView
    }
    
    @IBOutlet weak var cancelButtonLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBarLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!

    var search: Search? {
        didSet {
            self.search?.delegate = self
        }
    }

    var lastSearch: String?
    var results: [SearchResult] = [] {
        didSet {
            self.searchResults.isHidden = results.isEmpty
            self.searchResults.reloadData()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            self.searchBar.textField?.backgroundColor = Colors.searchBarColor
            self.searchBar.textField?.font = UIFont(name: "AvenirNext", size: 17)
            self.searchBar.textField?.clearButtonMode = .never;
            self.searchBar.backgroundImage = UIImage()
            self.searchBar.delegate = self
        }
    }

    @IBOutlet weak var searchResults: UITableView! {
        didSet {
            self.searchResults.delegate = self
            self.searchResults.dataSource = self
            let nib = UINib(nibName: "SearchResultCell", bundle: nil)
            self.searchResults.register(nib, forCellReuseIdentifier: "SearchResultCell")
        }
    }
    
    typealias locationCallback = (Location) -> ()
    var onSelected: locationCallback?
    
    typealias actionOccured = () -> ()
    var onSearchWasSelected: actionOccured?
    var onSearchWasClosed: actionOccured?
    
    typealias searchResized = (Int) -> ()
    var onResultsNeedSpace: searchResized?

    func closeSearchBar() {
        if let index = self.searchResults.indexPathForSelectedRow{
            self.searchResults.deselectRow(at: index, animated: true)
        }
        self.lastSearch = searchBar.text
        self.removeConstraint(cancelButtonLayoutConstraint)
        self.addConstraint(searchBarLayoutConstraint)
        self.searchBar.endEditing(true)
        self.cancelButton.isHidden = true
        onResultsNeedSpace?(0)
        UIView.animate(withDuration: 0.4) {
            self.layoutIfNeeded()
        }
    }

    func cancelSearchBar() {
        closeSearchBar()
        onSearchWasClosed?()
        self.searchBar.resignFirstResponder()
        searchBar.text = ""
        lastSearch = ""
        onResultsNeedSpace?(0)
    }

    @IBAction func cancledPressed(_ sender: Any) {
        cancelSearchBar()
    }
}

extension SearchView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        lastSearch = searchText
        if lastSearch!.count < 1 {
            results = []
            onResultsNeedSpace?(0)
        } else {
            if self.cancelButton.isHidden {
                self.removeConstraint(searchBarLayoutConstraint)
                self.addConstraint(cancelButtonLayoutConstraint)
                UIView.animate(
                    withDuration: 0.4,
                    animations: {
                        self.layoutIfNeeded()
                },
                    completion: { _ in
                        self.cancelButton.isHidden = false
                })
            }
            search?.search(query: searchText, page: 1, timeout: 1)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.removeConstraint(searchBarLayoutConstraint)
        self.addConstraint(cancelButtonLayoutConstraint)
        UIView.animate(
            withDuration: 0.4,
            animations: {
                self.layoutIfNeeded()
            },
            completion: { _ in
                self.cancelButton.isHidden = false
            }
        )
        if let previousSearch = self.lastSearch, previousSearch.count > 0 {
            search?.search(query: previousSearch, page: 1, timeout: 1)
        }
        onSearchWasSelected?()
    }
}

extension SearchView: SearchDelegate {
    func search(query: String, pagination: SearchPagination, results: [SearchResult]) {
        if query != lastSearch {
            return
        }
        
        //Filters out any location that doesn't have a polygon attached to it.
        self.results = results.filter { result in
            switch result.value {
            case .location(let location):
                if let _ = location.polygons.makeIterator().next() {
                    return true
                }
            }
            return false
        }
        self.onResultsNeedSpace?(self.results.count * 38)
    }
    
    func search(query: String, suggestions: [String]) {}
    func search(error: SearchError) {}
}

extension SearchView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = searchResults.dequeueReusableCell(
            withIdentifier: "SearchResultCell", for: indexPath
        ) as! SearchResultCell
        
        switch results[indexPath.row].value {
        case .location(let location):
            cell.textLabel?.insetsLayoutMarginsFromSafeArea = true
            cell.textLabel?.textColor = .white
            cell.textLabel?.text = location.name
        }
        cell.textLabel?.font = UIFont(name: "AvenirNext", size: 20)
        cell.backgroundColor = .clear
        cell.tintColor = Colors.azure
        let selectedView = UIView()
        selectedView.backgroundColor = Colors.searchBarColor
        cell.selectedBackgroundView = selectedView

        return cell
    }
}

extension SearchView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch results[indexPath.row].value {
        case .location(let location):
            self.onSelected?(location)
            closeSearchBar()
            onSearchWasClosed?()
            self.searchBar.resignFirstResponder()
        }
    }
}

extension UISearchBar {
    var textField: UITextField? {
        return subviews.first?.subviews.first(where: { $0.isKind(of: UITextField.self) }) as? UITextField
    }
}

class SearchResultCell: UITableViewCell {}
