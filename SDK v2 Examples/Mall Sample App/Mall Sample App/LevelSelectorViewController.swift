//
//  LevelSelectorViewController.swift
//  Mall Sample App
//
//  Created by Tobi Burnett on 2020-09-30.
//  Copyright © 2020 Mappedin. All rights reserved.
//

import UIKit
import Mappedin
import Mapbox

class LevelSelectorViewController: UIViewController {

    
    var mapView: MiMapView!
    var pickerViewHelper: PickerViewHelper!
    var venue: MiVenue!
    var previousLevel: MiLevel!
    var venueLevel: UILabel!
    @IBOutlet weak var levelSelector: UIPickerView!
    
    @IBAction func toolbarCancel(_ sender: Any) {
        mapView.setLevel(level: previousLevel)
        self.venueLevel.text = previousLevel.name
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toolbarDone(_ sender: Any) {
        self.venueLevel.text = self.mapView.currentLevel?.name
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previousLevel = self.mapView.currentLevel
        self.pickerViewHelper = PickerViewHelper(mapView: self.mapView)
        levelSelector.dataSource = self.pickerViewHelper
        levelSelector.delegate = self.pickerViewHelper
        levelSelector.selectRow(venue.levels.firstIndex(of: self.mapView.currentLevel!) ?? 0, inComponent: 0, animated: false)
    }
}


class PickerViewHelper: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // The levels from the map view will be displayed in the picker, and we want the picker to change the map view's level, so we'll store the map view here
    let mapView: MiMapView

    init(mapView: MiMapView) {
        self.mapView = mapView
        super.init()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // This tells the picker view how many rows to display
    // We want to display a row for each level of the map view, so we'll take the number of the map view's levels
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mapView.levels.count
    }
    
    // This tells the picker view what to display for a certain row
    // We'll display the corresponding level's name
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return(mapView.levels[row].name)
    }
    
    // This tells the picker view what to do upon row selection
    // We'll set the map view to the selected row's level
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mapView.setLevel(level: mapView.levels[row])
    }
}
