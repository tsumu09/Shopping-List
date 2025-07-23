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
            let data: [String: Any] = [
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

    func observeShopsAndItems(groupId: String, completion: @escaping ([Shop]) -> Void) -> ListenerRegistration {
        let shopsRef = db.collection("groups").document(groupId).collection("shops")
        
        var loadedShops: [Shop] = []
        var itemListeners: [ListenerRegistration] = []
        
        let shopsListener = shopsRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("ショップの読み込み失敗: \(error?.localizedDescription ?? "不明なエラー")")
                completion([])
                return
            }
            
            // 既存のitemsリスナーは一旦解除してクリア
            itemListeners.forEach { $0.remove() }
            itemListeners.removeAll()
            loadedShops.removeAll()
            
            for doc in documents {
                let data = doc.data()
                let shopId = doc.documentID
                let name = data["name"] as? String ?? ""
                let latitude = data["latitude"] as? Double ?? 0.0
                let longitude = data["longitude"] as? Double ?? 0.0
                
                var shop = Shop(name: name, latitude: latitude, longitude: longitude, items: [], isExpanded: false)
                
                // itemsサブコレクションの監視
                let itemsListener = shopsRef.document(shopId).collection("items").addSnapshotListener { itemSnapshot, error in
                    guard let itemDocs = itemSnapshot?.documents else {
                        print("アイテムの読み込み失敗: \(error?.localizedDescription ?? "不明なエラー")")
                        completion([])
                        return
                    }
                    
                    let items = itemDocs.compactMap { itemDoc -> Item? in
                        let itemData = itemDoc.data()
                        return Item(
                            name: itemData["name"] as? String ?? "",
                            price: itemData["price"] as? Int ?? 0,
                            deadline: (itemData["deadline"] as? Timestamp)?.dateValue() ?? Date(),
                            detail: itemData["detail"] as? String ?? "",
                            importance: itemData["importance"] as? Int ?? 0,
                            isChecked: itemData["isChecked"] as? Bool ?? false
                        )
                    }
                    
                    // loadedShopsに該当shopがあれば更新、なければ追加
                    if let index = loadedShops.firstIndex(where: { $0.name == shop.name }) {
                        loadedShops[index].items = items
                    } else {
                        shop.items = items
                        loadedShops.append(shop)
                    }
                    
                    // completion呼び出し（リアルタイム更新）
                    completion(loadedShops)
                }
                
                itemListeners.append(itemsListener)
            }
        }
        
        return shopsListener
    }
    
    
    
    /// shopsを一括取得（itemsは配列フィールドとしてまとめて持っている場合）
    func fetchGroupShops(groupId: String, completion: @escaping ([Shop]) -> Void) {
        db.collection("groups").document(groupId).collection("shops").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching shops: \(error?.localizedDescription ?? "unknown error")")
                completion([])
                return
            }
            
            let shops: [Shop] = documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let itemDicts = data["items"] as? [[String: Any]] else {
                    return nil
                }
                
                let items: [Item] = itemDicts.compactMap { itemData in
                    guard let itemName = itemData["name"] as? String,
                          let isChecked = itemData["isChecked"] as? Bool,
                          let price = itemData["price"] as? Int,
                          let detail = itemData["detail"] as? String,
                          let importance = itemData["importance"] as? Int,
                          let deadline = itemData["deadline"] as? Timestamp else {
                        return nil
                    }
                    
                    return Item(
                        name: itemName,
                        price: price,
                        deadline: deadline.dateValue(),
                        detail: detail,
                        importance: importance,
                        isChecked: isChecked
                    )
                }
                
                return Shop(
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    items: items,
                    isExpanded: false
                )
            }
            
            completion(shops)
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
