//
//  TotalAmountViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/09.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TotalAmountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var passedShopName: String?
    var fetchedShopNames: [String] = []
    var groupId: String!
    var shopName: String?
    var itemsListener: ListenerRegistration?
    var shopId: String!
    var shops: [Shop] = []
    
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShopItemCell", for: indexPath) as! ShopItemCell
            let item = shops[indexPath.section].items[indexPath.row - 1]
            
            cell.item = item
            cell.nameLabel.text = item.name
            cell.priceTextField.text = String(format: "%.2f", item.price)
            cell.importance = item.importance
            cell.section = indexPath.section
            cell.row = indexPath.row - 1
            cell.delegate = self
            
            return cell
        }
    }
}

extension TotalAmountViewController: ShopItemCellDelegate {
    func shopItemCell(_ cell: ShopItemCell, didUpdatePrice price: Double, section: Int, row: Int) {
        shops[section].items[row].price = price
        
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
