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
    
    @IBAction func SignUpButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
        let password = passwordTextField.text, !password.isEmpty
        else {
            errorLabel.text = "メールアドレスとパスワードを入力してください。"
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.errorLabel.text = error.localizedDescription
                return
            }
            guard let user = result?.user else {
                self.errorLabel.text = "ユーザー情報が取得できませんでした。"
                return
            }
            print("サインアップに成功しました: \(user.uid)")
            self.errorLabel.text = "サインアップ成功！"
        }
        
    }

}
