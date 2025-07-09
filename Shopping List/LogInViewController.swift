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
}
