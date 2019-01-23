//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 1/21/18.
//  Copyright © 2018 Ryan Berry. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
   var coreData = CoreDataStack()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        coreData.saveContext()
    }


    
}

