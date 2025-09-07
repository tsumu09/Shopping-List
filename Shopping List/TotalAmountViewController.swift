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
    var sectionKeys: [(month: String, shopId: String, shopName: String)] = []
    var shopNamesById: [String: String] = [:]
    var uidToDisplayName: [String: String] = [:]
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    var displayedItems: [String: [Item]] = [:]
    var monthlyItems: [String: [Item]] = [:]
    var currentMonthKey: String = ""
    
    private var itemListeners: [String: ListenerRegistration] = [:] // shop.id -> listener
    let db = Firestore.firestore()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var monthlyTotalLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
            tableView.delegate = self
        fetchUserNames()
            updateMonthLabel()
        
        let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年M月"
            currentMonthKey = formatter.string(from: Date())
////        fetchAllShops {
////                self.startAllListeners()
//            }
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
        super.viewWillAppear(animated)
        print("viewWillAppear 呼ばれた")

        guard let uid = Auth.auth().currentUser?.uid else { return }

        // ユーザー情報取得
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let data = snapshot?.data(), let groupId = data["groupId"] as? String {
                print("取得した groupId:", groupId)
                self.groupId = groupId

                // 取得完了後にショップ情報ロード
                self.fetchAllShops {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()  // ショップ名を反映
                        self.startAllListeners()     // Listener開始
                    }
                }

            } else {
                print("groupId が取得できなかった")
                // 必要に応じて fetchGroupIdIfNeeded をここで呼ぶ
            }
        }
    }

    
    private func fetchGroupIdIfNeeded(completion: @escaping (Bool) -> Void) {
        if let groupId = self.groupId, !groupId.isEmpty {
            // 既に取得済み
            completion(true)
            return
        }
    }
    
    private func startAllListeners() {
        stopAllItemListeners()
        guard let groupId = self.groupId else { return }

        // ① ショップ名辞書を先に作る
        db.collection("groups").document(groupId).collection("shops").getDocuments { snapshot, _ in
            self.shopNamesById.removeAll()
            snapshot?.documents.forEach { d in
                let shopName = d["name"] as? String ?? "不明"
                self.shopNamesById[d.documentID] = shopName
            }

            // shopNamesById 作成後に listener を追加
            self.startItemsListener()
        }
    }

    private func startItemsListener() {
        guard let groupId = self.groupId else { return }

        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: self.currentDate))!
        var comps = DateComponents(); comps.month = 1; comps.second = -1
        let endOfMonth = cal.date(byAdding: comps, to: startOfMonth)!

        self.itemsListener = self.db.collectionGroup("items")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("isChecked", isEqualTo: true)
            .whereField("purchasedDate", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
            .whereField("purchasedDate", isLessThanOrEqualTo: Timestamp(date: endOfMonth))
            .addSnapshotListener { snap, err in
                guard let snap = snap else { return }

                var allItems: [Item] = []

                for doc in snap.documents {
                    let d = doc.data()
                    let item = Item(
                        id: doc.documentID,
                        shopId: d["shopId"] as? String ?? "",
                        name: d["name"] as? String ?? "",
                        price: (d["price"] as? NSNumber)?.doubleValue ?? (d["price"] as? Double ?? 0),
                        isChecked: d["isChecked"] as? Bool ?? false,
                        importance: d["importance"] as? Int ?? 1,
                        detail: d["detail"] as? String ?? "",
                        deadline: (d["deadline"] as? Timestamp)?.dateValue(),
                        requestedBy: d["requestedBy"] as? String ?? "",
                        buyerIds: d["buyerIds"] as? [String] ?? [],
                        purchaseIntervals: (d["purchaseIntervals"] as? [Int]) ?? ((d["purchaseIntervals"] as? [Double])?.map { Int($0) } ?? []),
                        averageInterval: d["averageInterval"] as? Double,
                        purchaseHistory: (d["purchaseHistory"] as? [Timestamp])?.map { $0.dateValue() } ?? [],
                        isAutoAdded: d["isAutoAdded"] as? Bool ?? false,
                        groupId: d["groupId"] as? String ?? groupId
                    )

                    // shopId が辞書にない場合はログ
                    if self.shopNamesById[item.shopId] == nil {
                        print("⚠️ shopId \(item.shopId) が shopNamesById に存在しません。Item名: \(item.name)")
                    }

                    allItems.append(item)
                }

                self.items = allItems
                self.groupItemsByMonthAndShop(items: allItems, shopNamesById: self.shopNamesById)
                self.updateTotalPriceInCells()
                self.tableView.reloadData()
            }
    }

    



    func loadData() {
        fetchAllShops {
            print("🟢 全ショップ取得完了:", self.shopNamesById)
            self.startAllListeners()
        }
    }

    private func stopAllItemListeners() {
        itemsListener?.remove()
        itemsListener = nil
    }
    
    func fetchAllShops(completion: @escaping () -> Void) {
        guard let groupId = self.groupId else {
            print("❌ groupId が nil です")
            completion()
            return
        }
        
        let db = Firestore.firestore()
        db.collection("groups")
            .document(groupId)
            .collection("shops")
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    if let error = error {
                        print("Error fetching shops: \(error)")
                    }
                    completion()
                    return
                }
                
                self.shops = [] // 既存の配列をリセット
                self.shopNamesById = [:] // 名前辞書もリセット
                
                for doc in docs {
                    let data = doc.data()
                    
                    let shopId = data["shopId"] as? String ?? doc.documentID
                    let name = data["name"] as? String ?? "不明"
                    let latitude = data["latitude"] as? Double ?? 0.0
                    let longitude = data["longitude"] as? Double ?? 0.0
                    
                    let shop = Shop(
                        id: shopId,      // Firestore の shopId を使用
                        name: name,
                        groupId: groupId,
                        latitude: latitude,
                        longitude: longitude,
                        items: [],       // items は後で fetchItems などで取得
                        isExpanded: true
                    )
                    
                    self.shops.append(shop)
                    self.shopNamesById[shopId] = name
                }
                
                completion()
            }
    }

//    private func fetchItemsAndReload() {
//        // このメソッドが全てのデータ取得とUI更新をまとめて行います
//        let calendar = Calendar.current
//        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
//        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
//
//        db.collection("groups").document(groupId).collection("shops").getDocuments { [weak self] snapshot, error in
//            guard let self = self, let shopsDocs = snapshot?.documents else { return }
//
//            self.shops = shopsDocs.map { doc in
//                let data = doc.data()
//                let name = data["name"] as? String ?? "不明なお店"
//                let lat = data["latitude"] as? Double ?? 0.0
//                let lng = data["longitude"] as? Double ?? 0.0
//                return Shop(id: doc.documentID, name: name, latitude: lat, longitude: lng, items: [])
//            }
//
//            let dispatchGroup = DispatchGroup()
//            var tempItemsByShop: [String: [Item]] = [:]
//
//            for shopDoc in shopsDocs {
//                dispatchGroup.enter()
//                shopDoc.reference.collection("items").getDocuments { itemSnap, error in
//                    defer { dispatchGroup.leave() }
//                    guard let itemDocs = itemSnap?.documents else { return }
//
//                    let itemsForShop = itemDocs.compactMap { doc -> Item? in
//                        return try? doc.data(as: Item.self)
//                    }.filter { item in
//                        if let lastPurchaseDate = item.purchaseHistory.last {
//                            return lastPurchaseDate >= startOfMonth && lastPurchaseDate <= endOfMonth
//                        }
//                        return false
//                    }
//                    tempItemsByShop[shopDoc.documentID] = itemsForShop
//                }
//            }
//
//            dispatchGroup.notify(queue: .main) {
//                self.items = tempItemsByShop.values.flatMap { $0 }
//                self.groupItemsByMonthAndShop(items: self.items)
//                self.prepareSectionKeys()
//                self.tableView.reloadData()
//                print("✨ データ取得とセクション準備が完了しました。")
//                print("✅ 最終的な sectionKeys: \(self.sectionKeys)")
//            }
//        }
//    }
    
//    func fetchUserNames() {
//        FirestoreManager.shared.fetchUserNames { names in
//            self.userNames = names
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
//    }

    
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
    
    func showMonth(_ monthKey: String) {
        currentMonthKey = monthKey
        tableView.reloadData()
    }
    
    func prepareSectionKeys() {
        sectionKeys = []
        let sortedMonths = itemsByMonthAndShop.keys.sorted()
        for month in sortedMonths {
            let shopDict = itemsByMonthAndShop[month]!
            for shopId in shopDict.keys.sorted() {
                let shopName = shops.first { $0.id == shopId }?.name ?? "不明"
                sectionKeys.append((month: month, shopId: shopId, shopName: shopName))
            }
        }
        print("✅ sectionKeys 更新: \(sectionKeys)")
    }

    func shopItemCell(_ cell: ShopListItemCell, didToggleCheckAt item: Item) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        shops[indexPath.section].items[indexPath.row] = item
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    
//    func fetchShopNames() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        Firestore.firestore()
//            .collection("users")
//            .document(uid)
//            .getDocument { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let error = error {
//                    print("ユーザーデータ取得失敗: \(error)")
//                    return
//                }
//                
//                guard let data = snapshot?.data(),
//                      let groupId = data["groupId"] as? String else {
//                    print("groupId が取得できませんでした")
//                    return
//                }
//                
//                self.groupId = groupId
//                
//                self.db.collection("groups")
//                    .document(groupId)
//                    .collection("shops")
//                    .getDocuments { snapshot, error in
//                        if let error = error {
//                            print("ショップ取得失敗: \(error)")
//                            return
//                        }
//                        
//                        guard let documents = snapshot?.documents else {
//                            print("ショップがありません")
//                            return
//                        }
//                        
//                        self.fetchedShopNames = documents.compactMap { doc in
//                            doc.data()["name"] as? String
//                        }
//                        
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                            print("取得したショップ名一覧: \(self.fetchedShopNames)")
//                        }
//                    }
//            }
//    }
    
    func updateCheckedItems() {
        checkedItemsByShop = shops.map { $0.items.filter { $0.isChecked } }
    }

    
//    func startCheckedItemsListener(for shop: Shop) {
//        guard let groupId = self.groupId else { return }
//        
//        let shopsRef = Firestore.firestore()
//            .collection("groups")
//            .document(groupId)
//            .collection("shops")
//        
//        // すべてのショップを監視
//        shopsRef.addSnapshotListener { [weak self] snapshot, error in
//            guard let self = self else { return }
//            if let error = error {
//                print("ショップ取得失敗: \(error)")
//                return
//            }
//            
//            var totalAmount = 0
//            var shopTotalprices: [String: Int] = [:]  // ショップごとの小計を保持
////            var shopTotalprices: [String: Int] = [:]  // ショップごとの小計を保持
//            
//            // 各ショップごとにループ
//            snapshot?.documents.forEach { shopDoc in
//                let shopId = shopDoc.documentID
//                let shopName = shopDoc.data()["name"] as? String ?? "不明なお店"
//                
//                shopsRef.document(shopId).collection("items")
//                    .whereField("isChecked", isEqualTo: true)
//                    .addSnapshotListener { itemSnapshot, itemError in
//                        if let itemError = itemError {
//                            print("商品取得失敗: \(itemError)")
//                            return
//                        }
//                        
//                        var shopTotal = 0
//                        itemSnapshot?.documents.forEach { itemDoc in
//                            let data = itemDoc.data()
//                            if let price = data["price"] as? Int {
//                                shopTotal += price
//                            }
//                        }
//                        
//                        shopTotalprices[shopName] = shopTotal
//                        
//                        // 全体合計を再計算
//                        totalAmount = shopTotalprices.values.reduce(0, +)
//                        
//                        DispatchQueue.main.async {
//                            // 全体の合計ラベル更新
//                            self.monthlyTotalLabel.text = "合計: \(totalAmount)円"
//                            
//                        }
//                    }
//            }
//        }
//    }


//    func fetchMonthlyTotal(for monthStart: Date, completion: @escaping (Int) -> Void) {
//        guard let groupId = groupId else { return }
//        
//        let calendar = Calendar.current
//        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
//        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
//        
//        var checkedItemsByShopTemp: [[Item]] = Array(repeating: [], count: self.shops.count)
//       
//
//        
//        Firestore.firestore()
//            .collection("groups")
//            .document(groupId)
//            .collection("shops")
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("月合計の取得失敗: \(error)")
//                    completion(0)
//                    return
//                }
//                
//                var total = 0
//                let dispatchGroup = DispatchGroup()
//                
//                snapshot?.documents.forEach { shopDoc in
//                    dispatchGroup.enter()
//                    
//                    shopDoc.reference.collection("items")
//                        .whereField("isChecked", isEqualTo: true)
//                        .whereField("purchasedDate", isGreaterThanOrEqualTo: startOfMonth)
//                        .whereField("purchasedDate", isLessThanOrEqualTo: endOfMonth)
//                        .getDocuments { itemsSnapshot, error in
//                            if let error = error {
//                                print("商品取得失敗: \(error)")
//                            } else {
//                                itemsSnapshot?.documents.forEach { itemDoc in
//                                    if let price = itemDoc.data()["price"] as? Double {
//                                        total += Int(price) // Double → Int に変換
//                                    }
//                                }
//                            }
//                            dispatchGroup.leave()
//                        }
//                }
//                
//                dispatchGroup.notify(queue: .main) {
//                    self.checkedItemsByShop = checkedItemsByShopTemp
//                    self.updateCheckedItems()
//
//                   
//                    
//
//                    self.tableView.reloadData()
//                }
//
//            }
//    }

    
//    func fetchItemsForCurrentMonth() {
//        guard let groupId = self.groupId else { return }
//        let calendar = Calendar.current
//        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
//        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
//
//        db.collection("groups").document(groupId).collection("shops").getDocuments { snapshot, error in
//            guard let shopsDocs = snapshot?.documents else { return }
//
//            self.shops = shopsDocs.map { doc in
//                let data = doc.data()
//                let name = data["name"] as? String ?? "不明なお店"
//                let lat = data["latitude"] as? Double ?? 0.0
//                let lng = data["longitude"] as? Double ?? 0.0
//                return Shop(id: doc.documentID, name: name, latitude: lat, longitude: lng, items: [])
//            }
//
//            let dispatchGroup = DispatchGroup()
//            var tempItemsByShop: [String: [Item]] = [:] // ショップごとにアイテムを一時保存
//
//            for shopDoc in shopsDocs {
//                dispatchGroup.enter()
//                shopDoc.reference.collection("items").getDocuments { itemSnap, error in
//                    defer { dispatchGroup.leave() }
//                    guard let itemDocs = itemSnap?.documents else { return }
//
//                    let itemsForShop = itemDocs.compactMap { doc -> Item? in
//                        return try? doc.data(as: Item.self)
//                    }.filter { item in
//                        // 日付フィルターを追加
//                        if let lastPurchaseDate = item.purchaseHistory.last {
//                            return lastPurchaseDate >= startOfMonth && lastPurchaseDate <= endOfMonth
//                        }
//                        return false
//                    }
//                    tempItemsByShop[shopDoc.documentID] = itemsForShop
//                }
//            }
//
//            dispatchGroup.notify(queue: .main) {
//                // 全てのデータ取得が完了した後に実行
//                self.items = tempItemsByShop.values.flatMap { $0 }
//                
//                // アイテムを月・ショップごとに整理
//                self.groupItemsByMonthAndShop(items: self.items)
//                self.prepareSectionKeys()
//                
//                self.tableView.reloadData()
//                print("✨ データ取得とセクション準備が完了しました。")
//                print("✅ 最終的な sectionKeys: \(self.sectionKeys)")
//            }
//        }
//    }

    // 月切り替えで呼ぶ
    func reloadTableForSelectedMonth() {
        let monthKey = "\(selectedYear)-\(selectedMonth)"

        // その月のデータだけ取り出す
        let shopsForMonth = itemsByMonthAndShop[monthKey] ?? [:]

        // sectionKeys をその月だけで作り直す
        sectionKeys = shopsForMonth.map { (shopId, items) in
            (month: monthKey, shopId: shopId, shopName: shopNamesById[shopId] ?? "不明")
        }.sorted { $0.shopName < $1.shopName } // 名前順に並べたい場合

        // テーブル表示用に items も取り出して保持
        displayedItems = shopsForMonth  // もし UITableViewDataSource 内で使う場合

        tableView.reloadData()
    }
    
    func updateMonthlyItems(for month: Date) {
        let allShops = ["ShopA", "ShopB", "ShopC"]
        var monthlyItems: [String: [Item]] = [:]

        for shop in allShops {
            monthlyItems[shop] = items.filter { item in
                // shopId から名前を取得
                let name = shopNamesById[item.shopId] ?? "不明"
                
                // shop 名が一致して、かつ purchaseHistory に指定月の購入日があるか
                return name == shop &&
                       item.purchaseHistory.contains { date in
                           Calendar.current.isDate(date, equalTo: month, toGranularity: .month)
                       }
            }
        }

        self.monthlyItems = monthlyItems
        tableView.reloadData()
    }



    func groupItemsByMonthAndShop(items: [Item], shopNamesById: [String: String]) {
        self.itemsByMonthAndShop.removeAll()
        
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy年M月" // 例: 2025年9月
        
        for item in items {
            let shopIdTrimmed = item.shopId.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for date in item.purchaseHistory {
                let monthKey = monthFormatter.string(from: date)
                
                if self.itemsByMonthAndShop[monthKey] == nil {
                    self.itemsByMonthAndShop[monthKey] = [:]
                }
                if self.itemsByMonthAndShop[monthKey]?[shopIdTrimmed] == nil {
                    self.itemsByMonthAndShop[monthKey]?[shopIdTrimmed] = []
                }
                
                // 月ごとにコピーを作成して追加
                var copy = item
                copy.purchaseHistory = [date] // この月の購入日だけ残す
                self.itemsByMonthAndShop[monthKey]?[shopIdTrimmed]?.append(copy)
            }
        }
        
        // sectionKeys を更新（新しい月が上にくる）
        self.sectionKeys = self.itemsByMonthAndShop
            .sorted { $0.key > $1.key }
            .flatMap { (month, shopDict) in
                shopDict.map { (shopId, _) in
                    (month: month, shopId: shopId, shopName: shopNamesById[shopId] ?? "不明")
                }
            }
        
        tableView.reloadData()
    }



    
    func numberOfSections(in tableView: UITableView) -> Int {
        let filteredKeys = sectionKeys.filter { $0.month == currentMonthKey }
        return filteredKeys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filteredKeys = sectionKeys.filter { $0.month == currentMonthKey }
        let sectionInfo = filteredKeys[section]

        guard let shopItemsDict = itemsByMonthAndShop[sectionInfo.month],
              let monthItems = shopItemsDict[sectionInfo.shopId] else {
            return 1 // 合計セルのみ
        }
        return 1 + monthItems.count
    }
    
    func updateMonthlyTotalLabel() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy年M月" // groupItemsByMonthAndShop と同じ形式

        let monthKey = monthFormatter.string(from: currentDate)

        var monthlyTotal: Int = 0

        if let shopDict = itemsByMonthAndShop[monthKey] {
            for (_, items) in shopDict {
                monthlyTotal += items.reduce(0) { $0 + Int($1.price) }
            }
        }

        monthlyTotalLabel.text = "合計: \(monthlyTotal)円"
    }




    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sectionKeys.count else { return nil }
        let key = sectionKeys[section]
        let sectionInfo = sectionKeys[section]
            return "\(sectionInfo.month)-\(sectionInfo.shopName)"
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt called, section: \(indexPath.section), row: \(indexPath.row)")

        let sectionInfo = sectionKeys[indexPath.section]
        guard let shopItemsDict = itemsByMonthAndShop[sectionInfo.month],
              let monthItems = shopItemsDict[sectionInfo.shopId] else {
            return UITableViewCell()
        }

        if indexPath.row == 0 {
            // 合計セル
            let cell = tableView.dequeueReusableCell(withIdentifier: "TotalAmountShopCell", for: indexPath) as! TotalAmountShopCell
            let total = monthItems.filter { $0.isChecked }.reduce(0) { $0 + Int($1.price) }
            cell.totalPriceLabel.text = "¥\(total)"
            let shop = shops.first { $0.id == sectionInfo.shopId }
            cell.shopNameLabel.text = shop?.name ?? "不明なお店"
            return cell
        } else {
            // アイテムセル
            let cell = tableView.dequeueReusableCell(withIdentifier: "TotalAmountItemCell", for: indexPath) as! TotalAmountItemCell
            let item = monthItems[indexPath.row - 1] // ✅ 全アイテムを使用
            cell.item = item
            cell.priceTextField.text = String(Int(item.price))
            cell.section = indexPath.section
            cell.row = indexPath.row - 1
            cell.delegate = self

            if !item.buyerIds.isEmpty {
                let names = item.buyerIds.map { uidToDisplayName[$0] ?? "不明" }
                print("Item:", item.name, "buyerIds:", item.buyerIds, "names:", names)
                cell.buyerLabel.text = names.joined(separator: ", ")

            } else {
                cell.buyerLabel.text = "不明"
                print("Item:", item.name, "buyerIds:", item.buyerIds)
            }



            cell.configure(with: item, uidToDisplayName: uidToDisplayName)
            return cell
        }
    }

    
    func fetchUserNames() {
        FirestoreManager.shared.fetchUserNames { namesDict in
            // namesDict の型は [String: String] なので、uid と displayName が直接取れる
            self.uidToDisplayName = namesDict
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }


    



    
    func updateTotalPriceInCells() {
        // リスナーで更新されるshops配列が最新であることを前提に、以下のように修正
        var totalAmount = 0.0

        // `itemsByMonthAndShop` を使って合計を計算
        for (_, shopItemsDict) in itemsByMonthAndShop {
            for (_, items) in shopItemsDict {
                let shopTotal = items.filter { $0.isChecked }.reduce(0) { $0 + $1.price }
                totalAmount += shopTotal
            }
        }

        // 全体合計を更新
        self.monthlyTotalLabel.text = "合計: ¥\(Int(totalAmount))"
        self.tableView.reloadData()
    }
    
//    func fetchCheckedItemsForMonth() {
//        guard let groupId = SessionManager.shared.groupId else { return }
//
//        let calendar = Calendar.current
//        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
//
//        var comps = DateComponents()
//        comps.month = 1     // 翌月
//        comps.second = -1   // 1秒引く → 今月末の23:59:59
//        let endOfMonth = calendar.date(byAdding: comps, to: startOfMonth)!
//
//        Firestore.firestore()
//            .collectionGroup("items")   // ← Firestoreルートから直接
//            .whereField("groupId", isEqualTo: groupId) // 必ず groupId で絞る
//            .whereField("isChecked", isEqualTo: true)
//            .whereField("purchasedDate", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
//            .whereField("purchasedDate", isLessThanOrEqualTo: Timestamp(date: endOfMonth))
//            .addSnapshotListener { (snapshot: QuerySnapshot?, error: Error?) in
//                    guard let snapshot = snapshot else {
//                        if let error = error {
//                            print("データ取得失敗: \(error)")
//                        }
//                        return
//                    }
//                    
//                    self.items = snapshot.documents.compactMap { doc in
//                        try? doc.data(as: Item.self)
//                    }
//                    
//                let total = self.items.reduce(0) { $0 + ($1.price) }
//                    self.monthlyTotalLabel.text = "¥\(total)"
//                    self.tableView.reloadData()
//                }
//
//    }

    
    @IBAction func prevMonthButtonTapped(_ sender: UIButton) {
        changeMonth(by: -1)
    }

    @IBAction func nextMonthButtonTapped(_ sender: UIButton) {
        changeMonth(by: 1)
    }




    func changeMonth(by value: Int) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        
        // currentDate を value か月進める
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            updateMonthLabel()
            
            // 月キーを更新
            currentMonthKey = formatter.string(from: newDate)
            print("Changed month:", currentMonthKey)
            
            // ここでは再グループ化しない！
            tableView.reloadData()
        }
        updateMonthlyTotalLabel()

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
        
        // チェック済みアイテム配列更新x
        updateCheckedItems()
        
        // セクション再描画
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

}
