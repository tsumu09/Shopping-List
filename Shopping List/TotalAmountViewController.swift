//
//  TotalAmountViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/09.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TotalAmountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var passedShopName: String?
    var fetchedShopNames: [String] = []
    var groupId: String!
    var shopName: String?
    var itemsListener: ListenerRegistration?
    var shopId: String!
    var shops: [Shop] = []
    var items: [Item] = []
    var item: Item?
    private var itemListeners: [String: ListenerRegistration] = [:] // shop.id -> listener
    let db = Firestore.firestore()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let data = snapshot?.data(), let groupId = data["groupId"] as? String {
                self.groupId = groupId
                
                self.fetchShopNames()
                
                FirestoreManager.shared.observeShops(in: groupId) { shops in
                    self.shops = shops
                    
                    // ここでチェック済みアイテムだけ監視するリスナーを開始
                    for shop in self.shops {
                        self.startCheckedItemsListener(for: shop)
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }

            }
        }
    }
    
    func fetchShopNames() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("ユーザーデータ取得失敗: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let groupId = data["groupId"] as? String else {
                    print("groupId が取得できませんでした")
                    return
                }
                
                self.groupId = groupId
                
                self.db.collection("groups")
                    .document(groupId)
                    .collection("shops")
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("ショップ取得失敗: \(error)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            print("ショップがありません")
                            return
                        }
                        
                        self.fetchedShopNames = documents.compactMap { doc in
                            doc.data()["name"] as? String
                        }
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            print("取得したショップ名一覧: \(self.fetchedShopNames)")
                        }
                    }
            }
    }
    
    private func startCheckedItemsListener(for shop: Shop) {
            guard let groupId = self.groupId else { return }

            // 既にあれば解除してから（保険）
            itemListeners[shop.id]?.remove()

            let listener = Firestore.firestore()
                .collection("groups").document(groupId)
                .collection("shops").document(shop.id)
                .collection("items")
                .whereField("isChecked", isEqualTo: true)     // チェック済みだけ！
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Checked items 取得失敗(shop=\(shop.name)): \(error)")
                        return
                    }

                    let checkedItems: [Item] = snapshot?.documents.compactMap {
                        Item.fromDictionary($0.data(), id: $0.documentID)
                    } ?? []

                    // 対象ショップの items を「チェック済みだけ」に差し替える
                    if let idx = self.shops.firstIndex(where: { $0.id == shop.id }) {
                        self.shops[idx].items = checkedItems

                        // そのセクションだけ更新でOK
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }

                    }
                }

            itemListeners[shop.id] = listener
        }

    private func stopAllItemListeners() {
            for (_, lsn) in itemListeners {
                lsn.remove()
            }
            itemListeners.removeAll()
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return shops.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + shops[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // ショップ名セル
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else {
                return UITableViewCell()
            }
            let shop = shops[indexPath.section]
            cell.shopNameLabel.text = shop.name
            
            // 合計金額計算
            let total = shop.items.reduce(0) { $0 + $1.price }
            cell.totalPriceLabel.text = "¥\(Int(total))"
            
            return cell
        } else {
            // 商品セル
               let cell = tableView.dequeueReusableCell(withIdentifier: "TotalAmountItemCell", for: indexPath) as! TotalAmountItemCell
            let item = shops[indexPath.section].items[indexPath.row - 1]

               cell.item = item
               cell.itemNameLabel.text = item.name
               cell.priceTextField.text = String(format: "%.2f", item.price)
               cell.section = indexPath.section
               cell.row = indexPath.row - 1
               cell.delegate = self

               // ここで delegate を設定
               cell.priceTextField.delegate = cell

            cell.priceTextField.text = String(Int(item.price))
            
               return cell
           }
       }
    
    func updateTotalPriceInCells() {
        for section in 0..<shops.count {
            let total = shops[section].items.reduce(0) { $0 + Int($1.price) }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? ShopCell {
                cell.totalPriceLabel.text = "¥\(total)"
            }
        }
    }

//    
//
//    @objc func didReceiveItemNotification(_ notification: Notification) {
//        guard
//            let userInfo = notification.userInfo,
//            let shopId = userInfo["shopId"] as? String,
//            let itemId = userInfo["itemId"] as? String,
//            let groupId = SessionManager.shared.groupId   //  nilチェック
//                else {
//                    print("⚠️ groupId が nil です。Firestore 取得中止")
//                    return
//                }
//       
//        
//        Firestore.firestore()
//            .collection("groups")
//            .document(groupId)
//            .collection("shops")
//            .document(shopId)
//            .collection("items")
//            .document(itemId)
//            .getDocument { snapshot, error in
//                guard let data = snapshot?.data(), error == nil else { return }
//                            let item = Item.fromDictionary(data, id: snapshot!.documentID)
//                if item.isChecked {
//                                // idx を探して shops[idx].items に追加
//                                if let idx = self.shops.firstIndex(where: { $0.id == shopId }) {
//                                    self.shops[idx].items.append(item)
//                                    DispatchQueue.main.async {
//                                        self.tableView.reloadSections(IndexSet(integer: idx), with: .automatic)
//                                        self.updateTotalPriceInCells()
//                                    }
//                                } else {
//                                    print("⚠️ idx が見つかりません shopId = \(shopId)")
//                                }
//                            }
//                        }
//    }



}

extension TotalAmountViewController: TotalAmountItemCellDelegate {
    func TotalAmountItemCell(_ cell: TotalAmountItemCell, section: Int, row: Int) {
       
        // Firestoreに保存
        let shop = shops[section]
        let item = shops[section].items[row]
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shop, item: item) { error in
            if let error = error {
                print("アイテム更新失敗: \(error)")
            } else {
                print("アイテム更新成功")
            }
        }
        
        // 該当セクションだけ更新して合計金額を反映
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
    func didTapDetail(for item: Item) {
        // 詳細画面遷移処理
    }
}
