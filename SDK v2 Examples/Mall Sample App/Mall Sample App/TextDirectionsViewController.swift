//
//  TextDirectionsViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-10-01.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

class TextDirectionsViewController: UITableViewController {

    var instructions: [MiInstruction]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instructions?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InstructionTableViewCell", for: indexPath)
        
        let instruction = instructions?[indexPath.row]
        
        cell.textLabel?.text = instruction?.description
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        switch instruction?.action {
            case is Departure:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                cell.imageView?.image = UIImage(systemName: "smallcircle.circle.fill")
            case is Arrival:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                cell.imageView?.image = UIImage(systemName: "mappin.circle.fill")
            case is Turn:
                if let turn = instruction?.action as? Turn {
                    switch (turn.relativeBearing) {
                    case .left:
                        cell.imageView?.image = UIImage(systemName: "arrow.left.circle.fill")
                    case .slightLeft:
                        cell.imageView?.image = UIImage(systemName: "arrow.up.left.circle.fill")
                    case .straight:
                        cell.imageView?.image = UIImage(systemName: "arrow.up.circle.fill")
                    case .slightRight:
                        cell.imageView?.image = UIImage(systemName: "arrow.up.right.circle.fill")
                    case .right:
                        cell.imageView?.image = UIImage(systemName: "arrow.right.circle.fill")
                    }
                }
            case is TakeConnection:
                cell.imageView?.image = UIImage(systemName: "arrow.up.arrow.down.circle.fill")
            case is ExitConnection:
               cell.imageView?.image = UIImage(systemName: "arrow.up.arrow.down.circle.fill")
            default:
                cell.imageView?.image = UIImage(systemName: "re-center")
        }
        return cell
    }
    
    @IBAction func didTapCloseDirections(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
