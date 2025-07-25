//
//  SignUpViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import UIKit
import Foundation
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
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
                                        handler: { _ in
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self]result, error in
                guard let strongSelf = self else {
                    return
                }
                guard error == nil else {
                    print("サインアップに失敗しました")
                    return
                }
                print("サインインしました")
                let User = FirestoreUser(firstName: firstName, lastName: lastName, emailAddress: email)
                // userExists()でFirestoreにすでにユーザー情報(メールアドレス)が保存されていないかチェックする
                FirestoreManager.shared.userExists(uid: email) { exists in
                    if exists {
                        print("メールアドレスがすでに保存されています")
                        return
                    }
                    // insertUser()でFirestoreにユーザー情報を保存する
                    FirestoreManager.shared.insertUser(User, completion: { success in
                        if success {
                            print("ユーザー情報の保存が完了しました")
                            
                            DispatchQueue.main.async {
                                       let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                       if let groupVC = storyboard.instantiateViewController(withIdentifier: "GroupViewController") as? GroupViewController {
                                           if let nav = strongSelf.navigationController {
                                                               nav.pushViewController(groupVC, animated: true)
                                                           } else {
                                                               groupVC.modalPresentationStyle = .fullScreen
                                                               strongSelf.present(groupVC, animated: true)
                                                           }
                                       }
                                   }
                            return
                        }
                    })
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in }))
        present(alert, animated: true)
    }
}
