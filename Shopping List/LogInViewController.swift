//
//  LogInViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import UIKit
import Foundation
import FirebaseAuth
import FirebaseFirestore

class LogInViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
   

    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBAction func LogInButtonTapped(_ sender: UIButton) {
            guard let email = emailField.text,
                  let password = passwordField.text else { return }
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorLabel.text = error.localizedDescription
                    return
                }
                guard let user = result?.user else {
                    self.errorLabel.text = "ユーザー情報が取得できませんでした。"
                    return
                }
                // グループ所属チェック、正しい画面への遷移
                self.checkGroupMembership()
            }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.errorLabel.text = error.localizedDescription
                return
            }
            guard let user = result?.user else {
                self.errorLabel.text = "ユーザー情報が取得できませんでした。"
                return
            }
            
            // groupId取得処理を先に呼ぶ
            self.fetchGroupIdAfterLogin { error in
                if let error = error {
                    print("groupId 取得失敗: \(error.localizedDescription)")
                    // 失敗しても画面遷移したい場合はここで呼ぶ
                    DispatchQueue.main.async {
                        self.checkGroupMembership()
                    }
                } else {
                    print("groupId 取得成功: \(SessionManager.shared.groupId ?? "")")
                    DispatchQueue.main.async {
                        self.checkGroupMembership()
                    }
                }
            }
        }

        }
    private func checkGroupMembership() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let data = snapshot?.data(),
                   let groupId = data["groupId"] as? String,
                   !groupId.isEmpty {
                    SessionManager.shared.groupId = groupId // ← ここでセットする
                    self.switchRoot(to: "HomeTab")
                } else {
                    self.switchRoot(to: "GroupNav")
                }
            }
    }

    
    
private func switchRoot(to storyboardID: String) {
    DispatchQueue.main.async {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let delegate = windowScene.delegate as? SceneDelegate,
            let window = delegate.window
        else { return }
        
        let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(identifier: storyboardID)
        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}
    func fetchGroupIdAfterLogin(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AppError", code: 0, userInfo: [NSLocalizedDescriptionKey: "ログインしていません"]))
            return
        }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)
        
        userDocRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = documentSnapshot?.data(),
                  let groupId = data["groupId"] as? String else {
                completion(NSError(domain: "AppError", code: 1, userInfo: [NSLocalizedDescriptionKey: "groupId が見つかりません"]))
                return
            }
            
            SessionManager.shared.groupId = groupId
            print("groupId を取得・セットしました: \(groupId)")
            completion(nil)
        }
    }

    

}
