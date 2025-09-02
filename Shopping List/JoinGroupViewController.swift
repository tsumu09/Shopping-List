//
//  JoinGroupViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/31.
//

import UIKit
class JoinGroupViewController: UIViewController {
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "招待コードで参加"
        setupUI()
    }
    
    private func setupUI() {
        joinButton.layer.cornerRadius = 8
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: joinButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: joinButton.centerYAnchor)
        ])
    }
    
    @IBAction func joinTapped(_ sender: UIButton) {
      let code = codeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !code.isEmpty else {
        presentAlert(title: "エラー", message: "招待コードを入力してください")
        return
      }
        FirestoreManager.shared.joinGroup(withInviteCode: code) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let groupId):
              SessionManager.shared.groupId = groupId
              print("新しい groupId をセット:", groupId)
              // HomeTab に切り替え or 画面を閉じてリストをリロード
              let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
              let delegate = scene.delegate as! SceneDelegate
              let sb = UIStoryboard(name: "Main", bundle: nil)
              delegate.window?.rootViewController = sb.instantiateViewController(identifier: "HomeTab")
          case .failure(let err):
            self.presentAlert(title: "参加失敗", message: err.localizedDescription)
          }
        }
      }
        
    }
    
    private func setLoading(_ loading: Bool) {
        joinButton.isEnabled = !loading
        loading ? activityIndicator.startAnimating()
                : activityIndicator.stopAnimating()
    }
    
    private func presentAlert(title: String, message: String) {
        let a = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
        a.addAction(.init(title: "OK", style: .default))
        present(a, animated: true)
    }
}

