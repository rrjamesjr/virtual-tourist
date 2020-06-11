//
//  AppDelegate.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/8/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let dataController = DataController(modelName: "VirtualTour")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()
        checkIfFirstLaunch()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("App Delegate: will terminate")
        UserDefaults.standard.synchronize()
        dataController.save()
    }
    
    func checkIfFirstLaunch() {
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.centerCoordinateLatitude.rawValue) == nil {
            UserDefaults.standard.set(37.132840000000016, forKey: UserDefaultsKeys.centerCoordinateLatitude.rawValue)
            UserDefaults.standard.set(-95.785579999999981, forKey: UserDefaultsKeys.centerCoordinateLongitude.rawValue)
            UserDefaults.standard.set(86.24809813365279, forKey: UserDefaultsKeys.regionLatitudeDelta.rawValue)
            UserDefaults.standard.set(61.276014999999916, forKey: UserDefaultsKeys.regionLongitudeDelta.rawValue)
            UserDefaults.standard.set(18913418.08202306, forKey: UserDefaultsKeys.altitude.rawValue)
            UserDefaults.standard.synchronize()
        }
    }
}

