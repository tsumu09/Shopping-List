//
//  MemberListViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/27.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class MemberListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()
    var groupId: String?
    var members: [AppUser] = []
    var isAdmin: Bool = false
    var notifiedPendingIds: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        editProfileButton.setTitle("プロフィール編集", for: .normal)
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)

        // Firestore offline 設定（オプション）
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings

        loadMyUserData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let groupId = SessionManager.shared.groupId {
            self.groupId = groupId
            self.observeMembers()
            if isAdmin { self.observePendingMembers() }
        }
    }

    // MARK: - メールから safeEmail を作成
    func makeSafeEmail(from email: String) -> String {
        return email.lowercased()
                    .replacingOccurrences(of: ".", with: "-")
                    .replacingOccurrences(of: "@", with: "-")
    }



    // MARK: - プロフィール編集
    @objc func editProfileTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ProfileEditViewController") as? ProfileEditViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - 自分のユーザーデータ取得
    func loadMyUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("ユーザーデータ取得失敗: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else {
                print("ユーザーデータ取得失敗: ドキュメントが存在しない")
                return
            }

            DispatchQueue.main.async {
                if let displayName = data["displayName"] as? String {
                    let parts = displayName.split(separator: " ")
                    if parts.count >= 2 {
                        let firstName = parts[0]
                        let lastName = parts[1]
                        self.myNameLabel.text = "\(lastName) \(firstName)"
                    } else {
                        self.myNameLabel.text = displayName
                    }
                }

                self.groupId = data["groupId"] as? String
                self.isAdmin = data["isAdmin"] as? Bool ?? false

                self.observeMembers()
                if self.isAdmin {
                    self.observePendingMembers()
                }
            }
        }
    }

    // MARK: - 承認済みメンバー監視
    func observeMembers() {
        guard let groupId = self.groupId else { return }
        db.collection("groups").document(groupId)
          .collection("members")
          .addSnapshotListener { [weak self] snapshot, error in
              guard let self = self, let docs = snapshot?.documents else {
                  print("❌ snapshot or docs nil")
                  return
              }

              self.members = docs.compactMap { doc -> AppUser? in
                  let data = doc.data()
                  guard let displayName = data["displayName"] as? String else {
                      print("❌ displayName not found in \(doc.documentID)")
                      return nil
                  }

                  // 🔹 デバッグログ
                  print("Firestore displayName:", displayName)

                  let parts = displayName.split(separator: " ")
                  var reorderedName = displayName
                  if parts.count >= 2 {
                      let firstName = parts[0]   // 名
                      let lastName = parts[1]    // 姓
                      reorderedName = "\(lastName) \(firstName)"  // 姓 名
                  }

                  print("変換後:", reorderedName)

                  return AppUser(uid: doc.documentID, displayName: reorderedName, email: nil)
              }

              self.tableView.reloadData()
          }
    }


    // MARK: - pendingMembers 監視（作成者用）
    func observePendingMembers() {
        guard let groupId = self.groupId else { return }

        let pendingRef = db.collection("groups")
                           .document(groupId)
                           .collection("pendingMembers")

        // addSnapshotListener でリアルタイム監視
        pendingRef.addSnapshotListener { [weak self] snapshot, error in
            print("pendingMembers snapshot更新")
            guard let self = self, let docs = snapshot?.documents else { return }

            // ドキュメントが存在する場合のみ処理
            for doc in docs {
                let safeEmail = doc.documentID
                let firstName = doc.data()["displayName"] as? String ?? ""

                // アラート表示
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "参加希望",
                        message: "\(firstName) さんが参加希望です",
                        preferredStyle: .alert
                    )

                    // 承認ボタン
                    alert.addAction(UIAlertAction(title: "承認", style: .default, handler: { _ in
                        FirestoreManager.shared.approveMember(safeEmail: safeEmail, groupId: groupId) { error in
                            if let error = error {
                                print("承認失敗:", error.localizedDescription)
                            } else {
                                print("\(safeEmail) を承認しました")
                            }
                        }
                    }))

                    // 拒否ボタン
                    alert.addAction(UIAlertAction(title: "拒否", style: .destructive, handler: { _ in
                        doc.reference.delete { error in
                            if let error = error {
                                print("拒否失敗:", error.localizedDescription)
                            } else {
                                print("\(safeEmail) を拒否しました")
                            }
                        }
                    }))

                    self.present(alert, animated: true)
                }
            }
        }
    }


    // 承認処理
    func approveMember(safeEmail: String, groupId: String) {
        let pendingRef = db.collection("groups")
                           .document(groupId)
                           .collection("pendingMembers")
                           .document(safeEmail)

        let memberRef = db.collection("groups")
                          .document(groupId)
                          .collection("members")
                          .document(safeEmail)

        // pending からデータ取得
        pendingRef.getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            // members に追加
            memberRef.setData(data) { error in
                if let error = error {
                    print("メンバー追加失敗: \(error.localizedDescription)")
                    return
                }

                // pending から削除
                pendingRef.delete { error in
                    if let error = error {
                        print("pending 削除失敗: \(error.localizedDescription)")
                    } else {
                        print("\(safeEmail) を承認しました")
                    }
                }
            }
        }
    }
    

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let member = members[indexPath.row]
        print("Cell にセットする displayName:", member.displayName)
        cell.configure(with: member)
        return cell
    }
}
