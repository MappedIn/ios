//
//  SceneDelegate.swift
//  PlaygroundSamples
//
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Embed storyboard root in a navigation controller so the title shows in a nav bar
        guard let windowScene = scene as? UIWindowScene else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let root = storyboard.instantiateInitialViewController() ?? ViewController()
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
