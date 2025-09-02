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
    @IBAction func signUp(){
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty
        else{
            print("入力事項に不備があります")
            return
        }
        
        let alert = UIAlertController(title: "アカウント作成",
                                      message: "新しくアカウントを作成しますか？",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "はい",
                                      style: .default,
                                      handler: { [weak self] _ in
            guard let self = self else { return }

            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { result, error in
                guard error == nil, let user = result?.user else {
                    print("サインアップに失敗しました: \(error!.localizedDescription)")
                    return
                }
                print("サインインしました")

                // Firestore にユーザー保存
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)
                userRef.setData([
                    "displayName": "\(firstName) \(lastName)", // ←ここで苗字+名前を保存
                    "email": email
                ], merge: true)

                // もし FirestoreManager で管理してるなら、ここに組み合わせてもOK
                let fsUser = FirestoreUser(
                    firstName: firstName,
                    lastName: lastName,
                    emailAddress: email
                )
                FirestoreManager.shared.userExists(uid: user.uid) { exists in
                    if exists {
                        print("ユーザーがすでに存在しています")
                        return
                    }
                    FirestoreManager.shared.insertUser(fsUser) { success in
                        if success {
                            print("ユーザー情報の保存が完了しました")
                            self.switchRoot(to: "GroupNav")
                        }
                    }
                }
            }

            
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in }))
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
