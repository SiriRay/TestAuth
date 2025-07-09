//
//  TestAuthApp.swift
//  TestAuth
//
//  Created by Siriiii on 7/8/25.
//

import SwiftUI
import Firebase
import UIKit
import FirebaseAuth

@main
struct TestAuthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            InitialView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // 1. Set UNUserNotificationCenter delegate
           UNUserNotificationCenter.current().delegate = self

           // 2. Request permission for alerts/sounds/badges
           UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             if let err = error {
               print("❌ Notification auth error:", err)
             }
           }

           // 3. Actually register with APNs
           application.registerForRemoteNotifications()
        
        return true
    }
    // Called when APNs has given us a device token
      func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Let Firebase Auth know this device’s token
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        print("✅ APNs device token:", deviceToken.map { String(format: "%02x", $0) }.joined())
      }

    func application(_ application: UIApplication,
        didReceiveRemoteNotification notification: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      if Auth.auth().canHandleNotification(notification) {
        completionHandler(.noData)
        return
      }
      // This notification is not auth related; it should be handled separately.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        } else {
            return false
        }
              
    }
}
