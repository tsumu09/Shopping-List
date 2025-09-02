//
//  ProfileEditViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/27.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileEditViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserData()
    }
    
    
    func makeSafeEmail(from email: String) -> String {
        return email.lowercased()
                    .replacingOccurrences(of: ".", with: "-")
                    .replacingOccurrences(of: "@", with: "-")
    }


    /// Firestoreから現在のユーザー情報を取得して表示
    func loadUserData() {
        guard let email = Auth.auth().currentUser?.email else { return }
        print("ログイン中のメール:", email)
        let safeEmail = makeSafeEmail(from: email)
        print("safeEmail:", safeEmail)
        
        db.collection("users").document(safeEmail).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Firestore エラー: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("ユーザーデータ取得失敗: ドキュメントが存在しない")
                return
            }
            
            DispatchQueue.main.async {
                self?.firstNameTextField.text = data["first_name"] as? String ?? ""
                self?.lastNameTextField.text = data["last_name"] as? String ?? ""
                self?.emailLabel.text = data["email"] as? String ?? ""
            }
        }
    }


    
    /// 保存ボタン押したとき
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let email = Auth.auth().currentUser?.email else { return }

        let safeEmail = makeSafeEmail(from: email)
        print("safeEmail:", safeEmail)
        
        let firstName = firstNameTextField.text ?? ""
        let lastName = lastNameTextField.text ?? ""

        Firestore.firestore().collection("users").document(safeEmail).updateData([
            "first_name": firstName,
            "last_name": lastName
        ]) { [weak self] error in
            if let error = error {
                print("更新失敗: \(error.localizedDescription)")
            } else {
                print("更新成功！")
                let alert = UIAlertController(title: "更新完了", message: "プロフィールを更新しました。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self?.dismiss(animated: true)
                }))
                self?.present(alert, animated: true)
            }
        }
    }


    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("ログアウト成功")
            
            // 遷移先を StartViewController に変更
            if let startVC = storyboard?.instantiateViewController(withIdentifier: "StartViewController") {
                startVC.modalPresentationStyle = .fullScreen
                self.present(startVC, animated: true)
            }
            
        } catch let signOutError as NSError {
            print("ログアウト失敗: %@", signOutError)
            let alert = UIAlertController(title: "エラー", message: "ログアウトできませんでした。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

}
