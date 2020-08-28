//
//  TableViewController.swift
//  mapBox-Test
//
//  Created by Danielle Wang on 2020-06-11.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import MappedIn

class TableViewController: UITableViewController {
    
    var venue: MiVenue? = nil
    var venueNames: [String] = []
    var venueSlugs: [String] = []
    
    override func viewDidLoad() {
        let mappedIn = MappedIn()
        
        mappedIn.getVenues(completionHandler: {
            (resultCode, venues) -> (Void) in
            self.venueNames = venues.map({ $0.0 })
            self.venueSlugs = venues.map({ $0.1 })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venueNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell", for: indexPath)
        cell.textLabel?.text = venueNames[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "VenueSegue" {
            let venueSlug = venueSlugs[tableView.indexPathForSelectedRow!.row]
            if let destination = segue.destination as? MapViewController {
                destination.venueSlug = venueSlug
            }
        }
    }
}
