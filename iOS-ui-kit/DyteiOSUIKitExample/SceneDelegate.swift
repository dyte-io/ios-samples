//
//  SceneDelegate.swift
//  DyteiOSUIKitExample
//
//  Created by sudhir kumar on 27/01/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window : UIWindow?
    
}


extension SceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // This will allow us to check if we are coming from a universal link
        // and get the url with its components
        
        // The activity type (NSUserActivityTypeBrowsingWeb) is used
        // when continuing from a web browsing session to either
        // a web browser or a native app. Only activities of this
        // type can be continued from a web browser to a native app.
    }
    
}
