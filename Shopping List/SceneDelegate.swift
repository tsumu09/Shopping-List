//
//  SceneDelegate.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
                window = UIWindow(windowScene: windowScene)
                let sb = UIStoryboard(name: "Main", bundle: nil)

        if Auth.auth().currentUser == nil {
                    // 未ログイン → OnboardingNav を root にして即表示
                    let onboardingNav = sb.instantiateViewController(identifier: "OnboardingNav")
                    window?.rootViewController = onboardingNav
                    window?.makeKeyAndVisible()
                    print("未ログイン: OnboardingNav を表示")
                } else {
                    // ログイン済み → グループ所属チェック
                    print("ログイン済み: 所属チェック開始")
                    
                    // まず読込中画面 or OnboardingNav を出しておくと UX◎
                    let loadingNav = sb.instantiateViewController(identifier: "OnboardingNav")
                    window?.rootViewController = loadingNav
                    window?.makeKeyAndVisible()
                    
                    let uid = Auth.auth().currentUser!.uid
                    Firestore.firestore()
                        .collection("users").document(uid)
                        .getDocument { [weak self] snap, err in
                            guard let self = self else { return }
                            DispatchQueue.main.async {
                                if let data = snap?.data(),
                                   let groupId = data["groupId"] as? String,
                                   !groupId.isEmpty {
                                    // 所属あり → HomeTab
                                    let homeTab = sb.instantiateViewController(identifier: "HomeTab")
                                    self.window?.rootViewController = homeTab
                                    print("所属あり: HomeTab を表示")
                                } else {
                                    // 所属なし → OnboardingNav に push で GroupJoinCreateVC
                                    let groupNav = sb.instantiateViewController(identifier: "GroupNav")
                                    self.window?.rootViewController = groupNav
                                    print("所属なし: GroupNav を表示")

                                }
                            }
                        }
                }

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

