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
    var shopTotalprices: [String: Int] = [:]
    var currentMonth: Date = Date()
    var currentDate = Date()
    var allItems: [Item] = []
    var total: Double = 0
    var checkedItemsByShop: [[Item]] = []
    var userNames: [String: String] = [:]
    var purchaseHistory: [Date] = []
    var groupedByMonth: [String: [(date: Date, item: Item)]] = [:]
    var itemsByMonthAndShop: [String: [String: [Item]]] = [:]
    var sectionKeys: [(month: String, shopId: String)] = []
    
    private var itemListeners: [String: ListenerRegistration] = [:] // shop.id -> listener
    let db = Firestore.firestore()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var monthlyTotalLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        print("お店",shops)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        updateMonthLabel()
        fetchItemsForCurrentMonth()
        fetchUserNames()
        
        
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let currentMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        
        //ここで、monthly系は呼び出している。リスナーも、以下のメソッドの中で読んでます！
        
        fetchMonthlyTotal(for: currentMonthStart) { total in
            print("今月の合計: \(total)円")
        }
         */

        
        /*
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
                    self.checkedItemsByShop = self.shops.map { shop in
                            shop.items.filter { $0.isChecked }
                        }
                    
                    DispatchQueue.main.async {
                        self.updateTotalPriceInCells()
                        self.tableView.reloadData()
                    }
                }

            }
        }
         */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        
        print("お店",shops)
        print("セクション", sectionKeys)
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        
        
        updateMonthLabel()
        fetchItemsForCurrentMonth()
        fetchUserNames()
        
        
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let currentMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        
        //ここで、monthly系は呼び出している。リスナーも、以下のメソッドの中で読んでます！
        
        fetchMonthlyTotal(for: currentMonthStart) { total in
            print("今月の合計: \(total)円")
        }

        
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
                    self.checkedItemsByShop = self.shops.map { shop in
                            shop.items.filter { $0.isChecked }
                        }
                    
                    DispatchQueue.main.async {
                        self.updateTotalPriceInCells()
                        
                        self.tableView.reloadData()
                    }
                }

            }
        }
    }
    
    func fetchUserNames() {
        FirestoreManager.shared.fetchUserNames { names in
            self.userNames = names
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    
    func groupItemsByMonth(items: [Item]) {
        let calendar = Calendar.current
        let allEntries = items.flatMap { item in
            item.purchaseHistory.map { (date: $0, item: item) }
        }
        
        groupedByMonth = Dictionary(grouping: allEntries) { entry in
            let comps = calendar.dateComponents([.year, .month], from: entry.date)
            return "\(comps.year!)-itabl\(comps.month!)"
        }
    }

    func prepareSectionKeys() {
        sectionKeys = []
        let sortedMonths = itemsByMonthAndShop.keys.sorted()
        for month in sortedMonths {
            let shopDict = itemsByMonthAndShop[month]!
            for shopId in shopDict.keys.sorted() {
                sectionKeys.append((month: month, shopId: shopId))
            }
        }
    }


    func shopItemCell(_ cell: ShopListItemCell, didToggleCheckAt item: Item) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        shops[indexPath.section].items[indexPath.row] = item
        tableView.reloadRows(at: [indexPath], with: .automatic)
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
    
    func updateCheckedItems() {
        checkedItemsByShop = shops.map { $0.items.filter { $0.isChecked } }
    }

    
    func startCheckedItemsListener(for shop: Shop) {
        guard let groupId = self.groupId else { return }
        
        let shopsRef = Firestore.firestore()
            .collection("groups")
            .document(groupId)
            .collection("shops")
        
        // すべてのショップを監視
        shopsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("ショップ取得失敗: \(error)")
                return
            }
            
            var totalAmount = 0
            var shopTotalprices: [String: Int] = [:]  // ショップごとの小計を保持
//            var shopTotalprices: [String: Int] = [:]  // ショップごとの小計を保持
            
            // 各ショップごとにループ
            snapshot?.documents.forEach { shopDoc in
                let shopId = shopDoc.documentID
                let shopName = shopDoc.data()["name"] as? String ?? "不明なお店"
                
                shopsRef.document(shopId).collection("items")
                    .whereField("isChecked", isEqualTo: true)
                    .addSnapshotListener { itemSnapshot, itemError in
                        if let itemError = itemError {
                            print("商品取得失敗: \(itemError)")
                            return
                        }
                        
                        var shopTotal = 0
                        itemSnapshot?.documents.forEach { itemDoc in
                            let data = itemDoc.data()
                            if let price = data["price"] as? Int {
                                shopTotal += price
                            }
                        }
                        
                        shopTotalprices[shopName] = shopTotal
                        
                        // 全体合計を再計算
                        totalAmount = shopTotalprices.values.reduce(0, +)
                        
                        DispatchQueue.main.async {
                            // 全体の合計ラベル更新
                            self.monthlyTotalLabel.text = "合計: \(totalAmount)円"
                            
                        }
                    }
            }
        }
    }


    func fetchMonthlyTotal(for monthStart: Date, completion: @escaping (Int) -> Void) {
        guard let groupId = groupId else { return }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        var checkedItemsByShopTemp: [[Item]] = Array(repeating: [], count: self.shops.count)
       

        
        Firestore.firestore()
            .collection("groups")
            .document(groupId)
            .collection("shops")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("月合計の取得失敗: \(error)")
                    completion(0)
                    return
                }
                
                var total = 0
                let dispatchGroup = DispatchGroup()
                
                snapshot?.documents.forEach { shopDoc in
                    dispatchGroup.enter()
                    
                    shopDoc.reference.collection("items")
                        .whereField("isChecked", isEqualTo: true)
                        .whereField("purchasedDate", isGreaterThanOrEqualTo: startOfMonth)
                        .whereField("purchasedDate", isLessThanOrEqualTo: endOfMonth)
                        .getDocuments { itemsSnapshot, error in
                            if let error = error {
                                print("商品取得失敗: \(error)")
                            } else {
                                itemsSnapshot?.documents.forEach { itemDoc in
                                    if let price = itemDoc.data()["price"] as? Double {
                                        total += Int(price) // Double → Int に変換
                                    }
                                }
                            }
                            dispatchGroup.leave()
                        }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.checkedItemsByShop = checkedItemsByShopTemp
                    self.updateCheckedItems()

                    // ここでリスナー開始
                    for shop in self.shops {
                        self.startCheckedItemsListener(for: shop)
                    }

                    self.tableView.reloadData()
                }

            }
    }



    
    private func stopAllItemListeners() {
            for (_, lsn) in itemListeners {
                lsn.remove()
            }
            itemListeners.removeAll()
        }
    
    func fetchItemsForCurrentMonth() {
        guard let groupId = self.groupId else { return }
        self.items = allItems
        self.tableView.reloadData()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        self.groupedByMonth = Dictionary(grouping: items.flatMap { item in
            item.purchaseHistory.map { (date: $0, item: item) }
        }) { entry in
            let comps = calendar.dateComponents([.year, .month], from: entry.date)
            return "\(comps.year!)-\(comps.month!)"
        }

        db.collection("groups").document(groupId).collection("shops").getDocuments { snapshot, error in
            guard let shopsDocs = snapshot?.documents else { return }

            // 過去月でもお店だけは取得して配列を作る
            self.shops = shopsDocs.map { doc in
                let data = doc.data()
                let name = data["name"] as? String ?? "不明なお店"
                let lat = data["latitude"] as? Double ?? 0.0
                let lng = data["longitude"] as? Double ?? 0.0
                return Shop(id: doc.documentID, name: name, latitude: lat, longitude: lng, items: [])
            }

            let dispatchGroup = DispatchGroup()
            var checkedItemsByShopTemp: [[Item]] = Array(repeating: [], count: self.shops.count)

            for (index, shopDoc) in shopsDocs.enumerated() {
                let shopId = shopDoc.documentID
                dispatchGroup.enter()

                shopDoc.reference.collection("items").getDocuments { itemSnap, error in
                    defer { dispatchGroup.leave() }
                    guard let itemDocs = itemSnap?.documents else { return }

                    let allItems = itemDocs.compactMap { doc -> Item? in
                        try? doc.data(as: Item.self)
                    }

                
                    let checkedItems = allItems.filter { $0.isChecked }

                    // shops 配列に安全に代入
                    if let idx = self.shops.firstIndex(where: { $0.id == shopId }) {
                        self.shops[idx].items = checkedItems
                        checkedItemsByShopTemp[idx] = checkedItems
                    } else {
                        print("⚠️ shops 配列に shopId \(shopId) は存在しません")
                        print("現在のself.shopsのid一覧: \(self.shops.map { $0.id })")
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.checkedItemsByShop = checkedItemsByShopTemp
                    self.updateCheckedItems()

                    // アイテムを月・ショップごとに整理
                    self.groupItemsByMonthAndShop(items: self.items)
                    self.prepareSectionKeys()
                    
                    self.tableView.reloadData()
            }
        }
        groupItemsByMonthAndShop(items: self.items)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        let (monthKey, shopId) = sectionKeys[section]
        let shopItemsDict = itemsByMonthAndShop[monthKey] ?? [:]
        let monthItems = shopItemsDict[shopId] ?? []
        print(monthItems.count)
        return 1 + monthItems.count
    }


    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sectionKeys.count else { return nil }
        let (month, shopId) = sectionKeys[section]
        return "\(month) - \(shops.first { $0.id == shopId }?.name ?? "不明")"
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (monthKey, shopId) = sectionKeys[indexPath.section]
        guard let shopItemsDict = itemsByMonthAndShop[monthKey] else { return UITableViewCell() }
        let monthItems = shopItemsDict[shopId] ?? []   // ←ここを追加
        let shop = shops.first { $0.id == shopId }
        
        

        if indexPath.row == 0 {
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TotalAmountShopCell", for: indexPath) as! TotalAmountShopCell
            let total = monthItems.reduce(0) { $0 + Int($1.price) }
            
            cell.totalPriceLabel.text = "¥\(total)"
            cell.shopNameLabel.text = shop?.name ?? "不明なお店"
            return cell
        } else {
            
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TotalAmountItemCell", for: indexPath) as! TotalAmountItemCell
            let checkedItems = monthItems.filter { $0.isChecked }
            let item = checkedItems[indexPath.row - 1]

            
            cell.item = item
            cell.itemNameLabel.text = item.name
            cell.priceTextField.text = String(Int(item.price))
            cell.section = indexPath.section
            cell.row = indexPath.row - 1
            cell.delegate = self

            let buyers = item.buyerIds.compactMap { self.userNames[$0] }
            cell.buyerLabel.text = buyers.joined(separator: ", ")

            cell.configure(with: item)
            
            return cell
        }
    }

    

    
    func groupItemsByMonthAndShop(items: [Item]) {
        let calendar = Calendar.current
        var result: [String: [String: [Item]]] = [:]

        for item in items {
            for date in item.purchaseHistory {
                let comps = calendar.dateComponents([.year, .month], from: date)
                let monthKey = "\(comps.year!)-\(comps.month!)"

                if result[monthKey] == nil {
                    result[monthKey] = [:]
                }
                if result[monthKey]![item.shopId] == nil {
                    result[monthKey]![item.shopId] = []
                }
                result[monthKey]![item.shopId]!.append(item)
            }
        }
        self.itemsByMonthAndShop = result
    }



    
    func updateTotalPriceInCells() {
        
        print("おみせのかず", shops.count)
        print("セクション", sectionKeys)
        
        for section in 0..<shops.count {
            let total = shops[section].items.reduce(0) { $0 + Int($1.price) }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? TotalAmountShopCell {
                cell.totalPriceLabel.text = "¥\(total)"
                cell.shopNameLabel.text = shopName
                
            }
        }
        
    }
    
    func fetchCheckedItemsForMonth() {
        guard let groupId = SessionManager.shared.groupId else { return }

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!

        var comps = DateComponents()
        comps.month = 1     // 翌月
        comps.second = -1   // 1秒引く → 今月末の23:59:59
        let endOfMonth = calendar.date(byAdding: comps, to: startOfMonth)!

        Firestore.firestore()
            .collectionGroup("items")   // ← Firestoreルートから直接
            .whereField("groupId", isEqualTo: groupId) // 必ず groupId で絞る
            .whereField("isChecked", isEqualTo: true)
            .whereField("purchasedDate", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
            .whereField("purchasedDate", isLessThanOrEqualTo: Timestamp(date: endOfMonth))
            .addSnapshotListener { (snapshot: QuerySnapshot?, error: Error?) in
                    guard let snapshot = snapshot else {
                        if let error = error {
                            print("データ取得失敗: \(error)")
                        }
                        return
                    }
                    
                    self.items = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Item.self)
                    }
                    
                let total = self.items.reduce(0) { $0 + ($1.price) }
                    self.monthlyTotalLabel.text = "¥\(total)"
                    self.tableView.reloadData()
                }

    }

    
    @IBAction func prevMonthTapped(_ sender: UIButton) {
        changeMonth(by: -1)
    }

    @IBAction func nextMonthTapped(_ sender: UIButton) {
        changeMonth(by: 1)
    }

    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            updateMonthLabel()
            fetchItemsForCurrentMonth()
        }
    }

    func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        monthLabel.text = formatter.string(from: currentDate)
    }


    

    func updateItemCheckStatus(for item: Item, in shop: Shop) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var updatedItem = item

        if let index = updatedItem.buyerIds.firstIndex(of: uid) {
            // すでに買った → 削除
            updatedItem.buyerIds.remove(at: index)
            updatedItem.isChecked = !updatedItem.buyerIds.isEmpty
            if updatedItem.buyerIds.isEmpty {
                       // 削除なら purchaseHistory は変更なし
                   }
        } else {
            // 新たに購入者追加
            updatedItem.buyerIds.append(uid)
            updatedItem.isChecked = true
            updatedItem.purchaseHistory.append(Date())
        }

        FirestoreManager.shared.updateItem(groupId: groupId, shop: shop, item: updatedItem) { [weak self] error in
            if let error = error {
                print("更新失敗: \(error.localizedDescription)")
            } else {
                print("更新成功")
                // ↓ ②で修正
                self?.reloadItems(for: shop)
            }
        }
    }

    func reloadItems(for shop: Shop) {
        FirestoreManager.shared.fetchItems(groupId: groupId, shop: shop) { [weak self] (items: [Item]) in
            guard let self = self else { return }
            self.items = items
            self.tableView.reloadData()
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

extension TotalAmountViewController: ShopListItemCellDelegate {
    
    func shopListItemCell(_ cell: ShopListItemCell, didToggleCheckAt section: Int, row: Int) {
        // 配列更新
        let item = shops[section].items[row]
        shops[section].items[row] = item

        // Firestore 更新
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shops[section], item: item) { error in
            if let error = error {
                print("アイテム更新失敗: \(error)")
            } else {
                print("アイテム更新成功")
            }
        }

        // 該当セクションだけ再描画
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
    func shopListItemCell(_ cell: ShopListItemCell, didUpdatePrice price: Double, section: Int, row: Int) {
        // 価格変更時も同じデリゲートで対応
        shops[section].items[row].price = price
        let item = shops[section].items[row]
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shops[section], item: item) { error in
            if let error = error {
                print("価格更新失敗: \(error)")
            } else {
                print("価格更新成功")
            }
        }
        
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
    func shopListItemCell(_ cell: ShopListItemCell, didTapDetailFor item: Item) {
        // 詳細画面遷移
    }
    
    
}
extension TotalAmountViewController: TotalAmountItemCellDelegate {

    // 価格変更時
    func totalAmountItemCell(_ cell: TotalAmountItemCell, didUpdatePrice price: Double, section: Int, row: Int) {
        // 配列を更新
        shops[section].items[row].price = price
        let item = shops[section].items[row]
        
        print("item更新", item)

        // Firestore 更新
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shops[section], item: item) { error in
            if let error = error {
                print("価格更新失敗: \(error)")
            } else {
                print("価格更新成功")
            }
        }

        // 該当セクションだけ再描画
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

    // チェックボタン押下時
    func totalAmountItemCell(_ cell: TotalAmountItemCell, didToggleCheck section: Int, row: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var item = shops[section].items[row]
        
        // チェック状態をトグル
        item.isChecked.toggle()
        
        // チェックした場合は buyerIds に自分の UID を追加
        if item.isChecked {
            if !item.buyerIds.contains(uid) {
                item.buyerIds.append(uid)
            }
            // チェックした日を purchaseHistory に追加
            item.purchaseHistory.append(Date())
        } else {
            item.buyerIds.removeAll { $0 == uid }
            // アンチェック時に履歴を消すか残すかは要件次第
            // → 消すなら:
             if let last = item.purchaseHistory.last {
                 item.purchaseHistory.removeAll { $0 == last }
             }
        }


        
        // 配列更新
        func updateCheckedItems() {
            checkedItemsByShop = shops.map { $0.items.filter { $0.isChecked } }
        }

        // Firestore 更新
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shops[section], item: item) { error in
            if let error = error {
                print("チェック状態更新失敗: \(error)")
            } else {
                print("チェック状態更新成功")
            }
        }
        
        // チェック済みアイテム配列更新
        updateCheckedItems()
        
        // セクション再描画
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

}
