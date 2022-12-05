//
//  ViewController+UIPickerViewDataSource.swift
//  ios-sdk-app
//

import UIKit

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }
    
}
