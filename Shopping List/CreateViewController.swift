//
//  CreateViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/16.
//

import UIKit
import FirebaseAuth


class CreateViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var groupNameField: UITextField!
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    
    func setLoading(_ loading: Bool) {
        // 例えばローディングインジケーターを表示・非表示するとか
        print("Loading: \(loading)")
    }

    
    @IBAction func createGroupTapped(_ sender: UIButton) {
        view.endEditing(true)
        setLoading(true)
        
        //入力チェック
        let name = groupNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            presentAlert(title: "入力エラー", message: "グループ名を入力してください")
            setLoading(false)
            return
        }
        
        //FirestoreService でグループ作成
        FirestoreService.shared.createGroup(name: name) { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .failure(let error):
                self.presentAlert(title: "作成失敗", message: error.localizedDescription)
            case .success(let groupId):
                //ユーザードキュメントに groupId を保存
                guard let uid = Auth.auth().currentUser?.uid else {return}
                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .updateData(["groupId": groupId]) { error in
                        if let eroor = error {
                            self.presentAlert(title: "エラー", message: error.localizedDescription)
                        } else {
                            //ホーム画面へ
                        }
                    }
            }
        }
    }
    
}
