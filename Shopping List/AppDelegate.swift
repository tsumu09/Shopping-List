//
//  AppDelegate.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit
import FirebaseCore
import UserNotifications
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase 初期化
        FirebaseApp.configure()
       
        let db = Firestore.firestore()
                let settings = FirestoreSettings()
                settings.isPersistenceEnabled = true  // 必要なら設定
                db.settings = settings  // ✅ Firestore 初期化直後に設定
                
        // 通知権限リクエスト
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可OK")
            } else {
                print("通知許可拒否")
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if let autoAddedItemId = userInfo["itemId"] as? String {
            // ルートが UINavigationController で ShopListVC が最初にある場合
            if let nav = window?.rootViewController as? UINavigationController,
               let shopListVC = nav.viewControllers.first as? ShopListViewController {
                
                shopListVC.showAutoAddedItem(itemId: autoAddedItemId)
                nav.popToViewController(shopListVC, animated: true)
            }
        }
        completionHandler()
    }

}
