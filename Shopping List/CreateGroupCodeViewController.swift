//
//  CreateGroupCodeViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/31.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
class CreateGroupCodeViewController: UIViewController {
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var codeLabel: UILabel!
    
    var groupId: String!      // GroupVC からセット
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "招待コードを生成する"
        codeLabel.text = "—"
        generateButton.layer.cornerRadius = 8
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroupAndObserveMembers()
    }
    
    @IBAction func generateTapped(_ sender: UIButton) {
        sender.isEnabled = false
        codeLabel.text = "…生成中…"
        
        FirestoreManager.shared.generateInviteCode(
            for: groupId,
            validFor: 10
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                sender.isEnabled = true
                
                switch result {
                case .failure(let error):
                    self.codeLabel.text = "エラー"
                    self.presentAlert(title: "生成失敗", message: error.localizedDescription)
                    
                case .success(let code):
                    // ラベルに表示
                    self.codeLabel.text = code
                    // 有効期間の文言
                    let message = "この招待コードは10分間有効です。\nコード: \(code)"
                    // 共有
                    let act = UIActivityViewController(
                        activityItems: [message],
                        applicationActivities: nil
                    )
                    self.present(act, animated: true)
                }
            }
        }
    }
    
    private func fetchGroupAndObserveMembers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // まずユーザー情報から groupId を取得
        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      let gid = data["groupId"] as? String else { return }
                
                self.groupId = gid
            }
    }
    
    private func presentAlert(title: String, message: String) {
        let a = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        a.addAction(.init(title: "OK", style: .default))
        present(a, animated: true)
    }
}

