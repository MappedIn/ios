//
//  Example.swift
//  PlaygroundSamples
//

import UIKit

class Example {
    var title: String
    var description: String
    var viewController: UIViewController

    init(title: String, description: String, viewController: UIViewController) {
        self.title = title
        self.description = description
        viewController.title = title
        self.viewController = viewController
    }
}
