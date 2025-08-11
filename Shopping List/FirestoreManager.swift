//
//  FirestoreManager.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// ユーザー存在確認
    public func userExists(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error checking user existence: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(snapshot?.exists == true)
            }
        }
    }
    
    /// ユーザー登録
    public func insertUser(_ user: FirestoreUser, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(user.safeEmail).setData([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "email": user.emailAddress
        ]) { error in
            if let error = error {
                print("Failed to insert user: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User inserted successfully")
                completion(true)
            }
        }
    }
    
    static func safeEmail(_ email: String) -> String {
        return email.replacingOccurrences(of: ".", with: "-")
                    .replacingOccurrences(of: "@", with: "-")
    }
    
    func addShop(to groupId: String, name: String, latitude: Double, longitude: Double, completion: @escaping (Error?) -> Void) {
            let shopRef = db
                .collection("groups").document(groupId)
                .collection("shops").document()
            let data: [String: Any] = [
                "name": name,
                "latitude": latitude,
                "longitude": longitude
            ]
            shopRef.setData(data) { error in
                completion(error)
            }
        }
    
    func addItem(to groupId: String,
                 shopId: String,
                 name: String,
                 price: Double,
                 importance: Int,
                 detail: String,
                 completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let itemRef = db
            .collection("groups").document(groupId)
            .collection("shops").document(shopId)
            .collection("items").document()
        
        let itemId = itemRef.documentID  // ← ここでIDを取得

        let data: [String: Any] = [
            "id": itemId,                  // ← ここにIDを含める
            "name": name,
            "price": price,
            "importance": importance,
            "requestedBy": uid,
            "createdAt": Timestamp(),
            "detail": detail
        ]
        itemRef.setData(data) { error in
            completion(error)
        }
    }

    


    func updateItem(groupId: String, shop: Shop, item: Item, completion: ((Error?) -> Void)? = nil) {
        guard !item.id.isEmpty else {
            print("Error: item.id が空です。Firestore更新を中止します。")
            completion?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "item.id is empty"]))
            return
        }

        let db = Firestore.firestore()

        let docRef = db.collection("groups").document(groupId)
                       .collection("shops").document(shop.id)
                       .collection("items").document(item.id) // ← ここ！

        let data: [String: Any] = [
            "name": item.name,
            "price": item.price,
            "detail": item.detail,
            "deadline": Timestamp(date: item.deadline!),
            "importance": item.importance
        ]

        docRef.updateData(data) { error in
            if let error = error {
                print("Firestore 更新エラー: \(error.localizedDescription)")
            } else {
                print("Firestore 更新成功")
            }
            completion?(error)
        }
    }



    
    /// グループ作成（トランザクションでグループ本体＋メンバー初期追加）
    func createGroup(name: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let groupRef = db.collection("groups").document()
        let data: [String: Any] = [
            "name": name,
            "ownerId": uid
        ]
        
        db.runTransaction({ tx, _ in
            tx.setData(data, forDocument: groupRef)
            tx.setData([
                "joinedAt": Timestamp(),
                "displayName": Auth.auth().currentUser?.displayName ?? ""
            ], forDocument: groupRef.collection("members").document(uid))
            return nil
        }) { _, error in
            if let e = error {
                completion(.failure(e))
            } else {
                
                let shopRef = groupRef.collection("shops").document()
                            let shopData: [String: Any] = [
                                "name": "最初のお店",
                                "latitude": 0.0,
                                "longitude": 0.0,
                                "createdAt": Timestamp()
                            ]
                            shopRef.setData(shopData) { shopError in
                                if let shopError = shopError {
                                    print("初期ショップ追加失敗: \(shopError.localizedDescription)")
                                } else {
                                    print("初期ショップ追加成功")
                                }
                            }
                completion(.success(groupRef.documentID))
            }
        }
    }

    func observeShops(in groupId: String,
                          onUpdate: @escaping ([Shop]) -> Void) -> ListenerRegistration {
            let shopsRef = db
                .collection("groups").document(groupId)
                .collection("shops")
            return shopsRef.addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                var shops: [Shop] = []
                let dg = DispatchGroup()
                
                for d in docs {
                    // フィールドから位置情報を取得
                    let lat = d["latitude"] as? Double ?? 0
                    let lng = d["longitude"] as? Double ?? 0
                    
                    // 空の items で初期化
                    var shop = Shop(
                        id: d.documentID,
                        name: d["name"] as? String ?? "",
                        latitude: lat,
                        longitude: lng,
                        items: []
                    )
                    
                    dg.enter()
                    self.db
                        .collection("groups").document(groupId)
                        .collection("shops").document(d.documentID)
                        .collection("items")
                        .order(by: "importance", descending: true)
                        .getDocuments { itemsSnap, _ in
                            shop.items = itemsSnap?.documents.compactMap { i in
                                Item(
                                    name: i["name"] as? String ?? "",
                                    importance: i["importance"] as? Int ?? 0,
                                    deadline: i["deadline"] as? Date ?? Date(),
                                    detail: i["detail"] as? String ?? "",
                                    price: i["price"] as? Int ?? 0,
                                    id: i.documentID,
                                    requestedBy: i["deadline"] as? String ?? ""
                                )
                            } ?? []
                            shops.append(shop)
                            dg.leave()
                        }
                }
                
                dg.notify(queue: .main) {
                    onUpdate(shops)
                }
            }
        }
    
    // MARK: ランダム英数字コードを生成し、group/{groupId}/invites/{code} ドキュメントに
        // expiresAt (有効期限) をセットする
        func generateInviteCode(
            for groupId: String,
            validFor minutes: Int = 10,
            completion: @escaping (Result<String, Error>) -> Void
        ) {
            let code = randomString(length: 6)
            let expiresAt = Timestamp(date: Date().addingTimeInterval(TimeInterval(minutes * 60)))
            let inviteRef = db.collection("invites").document(code)
            let data: [String: Any] = [
                "groupId": groupId,
                "expiresAt": expiresAt
            ]
            inviteRef.setData(data) { error in
                if let e = error { completion(.failure(e)) }
                else           { completion(.success(code)) }
            }
        }
        
        
        // 英数字ランダム生成ヘルパー
        private func randomString(length: Int) -> String {
            let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
            return String((0..<length).map { _ in chars.randomElement()! })
        }
        
        // MARK: — グループ参加
        func joinGroup(groupId: String, completion: @escaping (Error?) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let memberRef = db
                .collection("groups").document(groupId)
                .collection("members").document(uid)
            memberRef.setData(["joinedAt": Timestamp(), "displayName": Auth.auth().currentUser?.displayName ?? ""]) { error in
                completion(error)
            }
        }
        
        // MARK: 招待コードから groupId を探して参加・ユーザードキュメントも更新する
        func joinGroup(withInviteCode code: String,
                       completion: @escaping (Result<String, Error>) -> Void) {
            let ref = db.collection("invites").document(code)
            ref.getDocument { snap, error in
                if let e = error { return completion(.failure(e)) }
                guard let data = snap?.data(),
                      let groupId = data["groupId"] as? String,
                      let expiresAt = data["expiresAt"] as? Timestamp
                else {
                    return completion(.failure(
                        NSError(domain:"", code:0,
                                userInfo:[NSLocalizedDescriptionKey:"無効な招待コードです"])
                    ))
                }
                // 期限チェック
                if expiresAt.dateValue() < Date() {
                    return completion(.failure(
                        NSError(domain:"", code:0,
                                userInfo:[NSLocalizedDescriptionKey:"このコードは期限切れです"])
                    ))
                }
                // メンバー登録 & users.groupId 更新
                self.joinGroup(groupId: groupId) { joinErr in
                    if let joinErr = joinErr {
                        return completion(.failure(joinErr))
                    }
                    guard let uid = Auth.auth().currentUser?.uid else {
                        return completion(.failure(
                            NSError(domain:"", code:0,
                                    userInfo:[NSLocalizedDescriptionKey:"ユーザー情報がありません"])
                        ))
                    }
                    self.db.collection("users")
                        .document(uid)
                        .updateData(["groupId": groupId]) { updErr in
                            if let updErr = updErr {
                                completion(.failure(updErr))
                            } else {
                                completion(.success(groupId))
                            }
                        }
                }
            }
        }

    
}

// ユーザーモデル
struct FirestoreUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        FirestoreManager.safeEmail(emailAddress)
    }
}

extension FirestoreManager {
    
    

}
