//
//  AppDelegate.swift
//  UpdatedExample
//
//  Created by Kashish Goel on 2017-11-09.
//  Copyright © 2017 Mappedin. All rights reserved.
//

import UIKit
import Mappedin

var service: Service? = nil
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    override init() {
        super.init()
        // this is the last tricky bit, the Service initializer requires
        // some extra swizzling on the AppDelegate in order allow our APIs
        // to get access to some internal messages that we need to do analytics
        // and background service integration.
        //
        // If your app crashes, you may see it walk through some of our SDK at the
        // bottom of the call stack. This is why.
        //
        // This must be initialized at this point, it's ugly, and I'm sorry this
        //  will be improved in the future. It can't be done before, nor after. :(
        service = Service(AppDelegate.self)
    }

}

