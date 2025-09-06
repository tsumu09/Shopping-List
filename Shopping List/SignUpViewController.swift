//
//  SignUpViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import UIKit
import Foundation
import FirebaseAuth
import UIKit
import FirebaseFirestore

class SignUpViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signUpButton.layer.cornerRadius = 10
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBAction func signUp() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty else {
            print("入力事項に不備があります")
            return
        }
        
        let alert = UIAlertController(
            title: "アカウント作成",
            message: "新しくアカウントを作成しますか？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    print("❌ サインアップに失敗: \(error.localizedDescription)")
                    return
                }
                guard let user = result?.user else { return }
                
                print("✅ サインアップ成功: \(user.uid)")
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "displayName": "\(firstName) \(lastName)",
                    "first_name": firstName,
                    "last_name": lastName,
                    "email": email,
                    "createdAt": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        print("❌ Firestore ユーザー保存失敗: \(error.localizedDescription)")
                    } else {
                        print("✅ Firestore ユーザー保存成功")
                        // 🔽 グループ作成画面に遷移
                        self.switchRoot(to: "GroupNav")
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        present(alert, animated: true)
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
