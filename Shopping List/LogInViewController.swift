//
//  LogInViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import UIKit
import Foundation
import FirebaseAuth

class LogInViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
   

    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
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
            print("ログインに成功しました: \(user.uid)")
            self.errorLabel.text = "ログイン成功！"
        }
        
        
    }
    
    func signUp(){
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
                FirestoreManager.shared.userExists(email: email) { exists in
                    if exists {
                        print("メールアドレスがすでに保存されています")
                        return
                    }
                    // insertUser()でFirestoreにユーザー情報を保存する
                    FirestoreManager.shared.insertUser(User, completion: { success in
                        if success {
                            print("ユーザー情報の保存が完了しました")
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
