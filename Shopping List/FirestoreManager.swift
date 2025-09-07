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
        let safeEmail = user.emailAddress.lowercased()
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
        
        db.collection("users").document(safeEmail).setData([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "email": user.emailAddress,   // オリジナル
            "raw_email": user.emailAddress
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
        return email.lowercased()
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
    }
    
    
    func makeSafeEmail(from email: String) -> String {
        return email.lowercased()
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
    }
    
    
    
    
    func addShop(to groupId: String,
                 name: String,
                 latitude: Double,
                 longitude: Double,
                 completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let shopRef = db
            .collection("groups").document(groupId)
            .collection("shops").document() // ← 自動生成のID
        let shopId = shopRef.documentID

        let data: [String: Any] = [
            "shopId": shopId,
            "groupId": groupId, // ← 追加
            "name": name,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": Timestamp(date: Date())
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
                 completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        let itemRef = db.collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shopId)
            .collection("items")
            .document() // ← 自動生成のID
        
        let itemId = itemRef.documentID
        let currentUser = Auth.auth().currentUser

        let itemData: [String: Any] = [
            "itemId": itemId,         // ← 追加
            "shopId": shopId,         // ← 追加
            "groupId": groupId,       // ← 追加
            "name": name,
            "price": price,
            "isChecked": false,
            "importance": importance,
            "detail": detail,
            "deadline": NSNull(),
            "requestedBy": currentUser?.displayName ?? "誰か",
            "createdAt": Timestamp(date: Date()),
            "buyerIds": [currentUser?.uid ?? ""], // ← arrayUnion は setData 時不要
            "purchaseIntervals": [], // 初期値は空
            "averageInterval": NSNull(), // まだ計算できないから null
            "isAutoAdded": false
        ]
        
        itemRef.setData(itemData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(itemId))
            }
        }
        
        // 通知を追加
        db.collection("groups")
            .document(groupId)
            .collection("notifications")
            .addDocument(data: [
                "message": "\(currentUser?.displayName ?? "誰か")が商品「\(name)」を追加しました",
                "timestamp": Timestamp(date: Date())
            ])
    }

    
    
    
    
    
    
    
    
    func updateItem(groupId: String, shop: Shop, item: Item, completion: ((Error?) -> Void)? = nil) {
        guard let itemId = item.id, !itemId.isEmpty else {
            print("Error: item.id が空です。Firestore更新を中止します。")
            completion?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "item.id is empty"]))
            return
        }
        
        let docRef = db.collection("groups").document(groupId)
            .collection("shops").document(shop.id)
            .collection("items").document(itemId)
        
        var updatedItem = item
        let now = Date()
        
        // 🔹購入日履歴を更新
        var history = updatedItem.purchaseHistory
        history.append(now)
        updatedItem.purchaseHistory = history
        
        // 🔹購入間隔を計算（2回以上購入していたら）
        let dates = updatedItem.purchaseHistory.sorted()
        if dates.count >= 2 {
            var intervals: [Double] = []
            for i in 1..<dates.count {
                let interval = dates[i].timeIntervalSince(dates[i-1]) / (60 * 60 * 24) // 日単位
                intervals.append(interval)
            }
            let avg = intervals.reduce(0, +) / Double(intervals.count)
            updatedItem.averageInterval = (avg * 10).rounded() / 10 // 小数第1位まで
        }
        
        
        let data: [String: Any] = [
            "name": updatedItem.name,
            "price": updatedItem.price,
            "detail": updatedItem.detail,
            "deadline": updatedItem.deadline != nil ? Timestamp(date: updatedItem.deadline!) : FieldValue.serverTimestamp(),
            "importance": updatedItem.importance,
            "isChecked": updatedItem.isChecked,
            "buyerIds": updatedItem.buyerIds,
            "purchaseHistory": updatedItem.purchaseHistory.map { Timestamp(date: $0) },
            "purchaseIntervals": updatedItem.purchaseIntervals,
            "averageInterval": updatedItem.averageInterval ?? 0
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
    
    func fetchItem(shopId: String, itemId: String, completion: @escaping (Item?) -> Void) {
        guard let groupId = SessionManager.shared.groupId else {
            completion(nil)
            return
        }
        
        db.collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shopId)
            .collection("items")
            .document(itemId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("アイテム取得失敗: \(error)")
                    completion(nil)
                    return
                }
                
                guard let data = snapshot?.data() else {
                    completion(nil)
                    return
                }
                
                // Item を Firestore データから生成
                let item = Item.fromDictionary(data, id: itemId)
                completion(item)
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
                    groupId: d["groupId"] as? String ?? "",
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
                            let data = i.data()
                            let priceNumber = data["price"] as? NSNumber
                            let price = priceNumber?.doubleValue ?? 0
                            let deadline = (data["deadline"] as? Timestamp)?.dateValue()
                            let rawIntervals = data["purchaseIntervals"] as? [Double] ?? []
                            let purchaseIntervals = (data["purchaseIntervals"] as? [Double] ?? []).map { Int($0) }
                            let isAutoAdded = data["isAutoAdded"] as? Bool ?? false
                            return Item(
                                id: i.documentID,
                                shopId: data["shopId"] as? String ?? "",
                                name: data["name"] as? String ?? "",
                                price: price,
                                isChecked: data["isChecked"] as? Bool ?? false,
                                importance: data["importance"] as? Int ?? 0,
                                detail: data["detail"] as? String ?? "",
                                deadline: deadline,
                                requestedBy: data["requestedBy"] as? String ?? "",
                                buyerIds: data["buyerIds"] as? [String] ?? [],
                                purchaseIntervals: purchaseIntervals,
                                averageInterval: data["averageInterval"] as? Double ?? 0.0,
                                isAutoAdded: isAutoAdded,
                                groupId: groupId
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
    
    func observeItems(in groupId: String, shopId: String, onUpdate: @escaping ([Item]) -> Void) -> ListenerRegistration {
        let itemsRef = db
            .collection("groups").document(groupId)
            .collection("shops").document(shopId)
            .collection("items")
            .order(by: "importance", descending: true)  // 並び順も指定できる
        
        return itemsRef.addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                print("itemsの取得失敗 or なし")
                onUpdate([])
                return
            }
            
            let items = docs.compactMap { d -> Item? in
                let data = d.data()
                
                let priceNumber = data["price"] as? NSNumber
                let price = priceNumber?.doubleValue ?? 0
                
                let deadlineTimestamp = data["deadline"] as? Timestamp
                let deadline = (data["deadline"] as? Timestamp)?.dateValue()
                
                let rawIntervals = data["purchaseIntervals"] as? [Double] ?? []
                let purchaseIntervals = (data["purchaseIntervals"] as? [Double] ?? []).map { Int($0) }

                let averageInterval = data["averageInterval"] as? Double
                let isAutoAdded = data["isAutoAdded"] as? Bool ?? false
                
                return Item(
                    id: d.documentID,
                    shopId: data["shopId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    price: price,
                    isChecked: data["isChecked"] as? Bool ?? false,
                    importance: data["importance"] as? Int ?? 0,
                    detail: data["detail"] as? String ?? "",
                    deadline: deadline,
                    requestedBy: data["requestedBy"] as? String ?? "",
                    buyerIds: data["buyerIds"] as? [String] ?? [],
                    purchaseIntervals: purchaseIntervals,
                    averageInterval: data["averageInterval"] as? Double ?? 0.0,
                    isAutoAdded: isAutoAdded,
                    groupId: groupId
                )
            }

            onUpdate(items)
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
                   let expiresAt = data["expiresAt"] as? Timestamp else {
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
             
             guard let uid = Auth.auth().currentUser?.uid else {
                 return completion(.failure(
                     NSError(domain:"", code:0,
                             userInfo:[NSLocalizedDescriptionKey:"ユーザー情報がありません"])
                 ))
             }
             
             let userDocRef = self.db.collection("users").document(uid)
             userDocRef.getDocument { snapshot, error in
                 guard let userData = snapshot?.data(),
                       let displayName = userData["displayName"] as? String else {
                     return completion(.failure(
                         NSError(domain:"", code:0,
                                 userInfo:[NSLocalizedDescriptionKey:"ユーザー情報取得失敗"])
                     ))
                 }
                 
                 // pendingMembers に追加
                 let pendingRef = self.db.collection("groups")
                     .document(groupId)
                     .collection("pendingMembers")
                     .document(uid)
                 
                 pendingRef.setData([
                     "joinedAt": Timestamp(),
                     "displayName": displayName,
                     "userDocId": uid
                 ]) { error in
                     if let error = error {
                         completion(.failure(error))
                     } else {
                         // users ドキュメントに groupId を merge
                         userDocRef.setData(["groupId": groupId], merge: true) { _ in
                             completion(.success(groupId))
                         }
                     }
                 }
             }
         }
     }

    
    
    
    func fetchItems(groupId: String, shop: Shop, completion: @escaping ([Item]) -> Void) {
        let db = Firestore.firestore()
        db.collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shop.id)
            .collection("items")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("商品取得失敗: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var items: [Item] = []
                snapshot?.documents.forEach { doc in
                    let item = Item.fromDictionary(doc.data(), id: doc.documentID)
                    items.append(item)
                }

                
                completion(items)
            }
    }
    
    func checkItem(_ item: Item, in shop: Shop) {
        guard let groupId = SessionManager.shared.groupId else { return }
            let shopId = shop.id          // ←そのままでOK
            guard let itemId = item.id else { return }
        
        let db = Firestore.firestore()
        
        // Item 更新
        db.collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shopId)
            .collection("items")
            .document(itemId)
            .updateData([
                "isChecked": true,
                "purchasedDate": Timestamp(date: Date()),
                "buyerIds": FieldValue.arrayUnion([Auth.auth().currentUser!.uid])
            ])
        
        // 通知を追加
        db.collection("groups")
            .document(groupId)
            .collection("notifications")
            .addDocument(data: [
                "message": "\(Auth.auth().currentUser?.displayName ?? "誰か")が\(item.name)を購入しました",
                "timestamp": Timestamp(date: Date())
            ])
    }
}
// ユーザーモデル
struct FirestoreUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        FirestoreManager.shared.makeSafeEmail(from: emailAddress)
    }

}

extension FirestoreManager {
    
    func deleteShop(groupId: String, shopId: String, completion: @escaping (Error?) -> Void) {
            let db = Firestore.firestore()
            let shopRef = db.collection("groups").document(groupId).collection("shops").document(shopId)
            
            shopRef.collection("items").getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }
                
                let batch = db.batch()
                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                batch.deleteDocument(shopRef)
                
                batch.commit { error in
                    completion(error)
                }
            }
        }
    func fetchUserNames(completion: @escaping ([String: String]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { snapshot, error in
            var names: [String: String] = [:]
            
            if let error = error {
                print("Error fetching users: \(error)")
                completion(names)
                return
            }
            
            if let docs = snapshot?.documents {
                for doc in docs {
                    let data = doc.data()
                    let uid = doc.documentID
                    let firstName = data["first_name"] as? String ?? ""
                    let lastName = data["last_name"] as? String ?? ""
                    let displayName = lastName + " " + firstName
                    names[doc.documentID] = displayName // ← uid がキーになる
                }
            }
            completion(names)
        }
    }
    
    func fetchUserDisplayNames(completion: @escaping ([String: String]) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            var names: [String: String] = [:]
            snapshot?.documents.forEach { doc in
                let uid = doc.documentID
                let displayName = doc.data()["displayName"] as? String ?? ""
                names[uid] = displayName
            }
            completion(names)
        }
    }


   
        /// pendingMembers の承認処理
    func approveMember(safeEmail: String, groupId: String, completion: @escaping (Error?) -> Void) {
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
                if let error = error {
                    completion(error)
                    return
                }
                guard let data = snapshot?.data() else {
                    completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "pending メンバーが存在しません"]))
                    return
                }
                
                // members に追加
                memberRef.setData(data) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // pending から削除
                    pendingRef.delete { error in
                        completion(error) // 成功なら error = nil
                    }
                }
            }
        }
    }
