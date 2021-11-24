//
//  ViewController+UIPickerViewDataSource.swift
//  ios-sdk-app
//
//  Created by Saman Sandhu on 2021-05-28.
//

import UIKit

extension ViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }

}
