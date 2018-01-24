//
//  AppDelegate.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/5/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import FBSDKCoreKit

import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self])

        
        // setup remote notifications
        // For iOS 10 display notification (sent via APNS)
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Register For Remote Notification failed: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        
        // Print full message.
        print(userInfo)
        
        DeepLinkManager.shared.handleRemoteNotification(userInfo) // get sender uid
        DeepLinkManager.shared.checkMessage()
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // This method will be called when app received push notifications in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let userInfo = notification.request.content.userInfo
        DeepLinkManager.shared.handleRemoteNotification(userInfo)
        
        if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController, let navc = tabBar.selectedViewController as? UINavigationController {
            let vc = navc.visibleViewController
            if let vc = vc as? ChatConversationViewController {
                if vc.toUid == DeepLinkManager.shared.getUid() {
                    vc.loadPage()
                    return
                }
            }
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
}

// jump to chat conversation when tap on chat notification
extension AppDelegate {
    class DeeplinkNavigator {
        static let shared = DeeplinkNavigator()
        
        private init() { }
        
        func gotoConversation(withUser uid: String) {
            
             if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController, let navc = tabBar.selectedViewController as? UINavigationController {
                
                let vc = navc.visibleViewController
                if let vc = vc as? ChatConversationViewController {
                        navc.popViewController(animated: false)
                }
                
                let conversationController = navc.storyboard?.instantiateViewController(withIdentifier: "conversationVC") as! ChatConversationViewController
                conversationController.toUid = uid
                navc.pushViewController(conversationController, animated: true)
            }
        }
    }
    
    class DeepLinkManager {
        static let shared = DeepLinkManager()
        fileprivate init() {}
        private var fromUid: String?

        // check existing deepling and perform action
        func checkMessage() {
            guard let uId = fromUid else {
                return
            }
            DeeplinkNavigator.shared.gotoConversation(withUser: uId)
            // reset deeplink after handling
            self.fromUid = nil // (1)
        }
        
        func getUid() -> String? {
            return fromUid
        }
        
        func handleRemoteNotification(_ notification: [AnyHashable: Any]) {
            fromUid = NotificationParser.shared.handleNotification(notification)
        }
    }
    
    class NotificationParser {
        static let shared = NotificationParser()
        private init() { }
        func handleNotification(_ userInfo: [AnyHashable : Any]) -> String? {
                if let fromUid = userInfo["fromUser"] as? String {
                    print (fromUid)
                    return fromUid
                }
            return nil
        }
    }
}

