//
//  CreateViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/16.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class CreateGroupViewController: UIViewController {
    
    var onGroupCreated: (() -> Void)?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        createGroupButton.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var createGroupButton: UIButton!
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
        FirestoreManager.shared.createGroup(name: name) { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .failure(let error):
                self.presentAlert(title: "作成失敗", message: error.localizedDescription)
            case .success(let groupId):
                // まずSessionManagerにgroupIdをセット
                SessionManager.shared.groupId = groupId
                print("グループ作成時にセットした groupId: \(SessionManager.shared.groupId ?? "nil")")
                guard let uid = Auth.auth().currentUser?.uid else {return}
                Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(["groupId": groupId], merge: true) { error in
                        if let error = error {
                            self.presentAlert(title: "エラー", message: error.localizedDescription)
                        } else {
                            // switchRootを用いてホーム画面へ
                            self.switchRoot(to: "HomeTab")
                            print("グループ作成後のSessionManager.shared.groupId = \(SessionManager.shared.groupId ?? "nil or empty")")

                        }
                    }

            }
        }
    }
    
}
extension UIViewController {
    func switchRoot(to storyboardID: String, storyboardName: String = "Main") {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: storyboardID)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            window.rootViewController = vc
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
    }
}
