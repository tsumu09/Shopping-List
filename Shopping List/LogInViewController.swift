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
                    // グループ所属済 → HomeTab へ
                    self.switchRoot(to: "HomeTab")
                } else {
                    // グループ未所属 → OnboardingNav に push
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
}
