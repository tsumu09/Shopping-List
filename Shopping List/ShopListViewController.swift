//
//  ViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/04/23.
//

import UIKit
import CoreLocation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore



class ShopListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var familyLabel: UILabel!
    
    let db = Firestore.firestore()
    var saveDate: UserDefaults = UserDefaults.standard
    var shopName: [String] = []
    var shops: [Shop] = []
    var groupId: String!
    var expandedSections: Set<Int> = []
    var listener: ListenerRegistration?
    var shopId: String?
    var selectedShopIndex: Int?
    var items: [Item] = []
    weak var delegate: ItemAddViewControllerDelegate?
    var itemsListener: [String: ListenerRegistration] = [:]
    let locationManager = CLLocationManager()
    let autoAddedLabel: UILabel = {
        let label = UILabel()
        label.text = "自動追加済みのアイテムがあります"
        label.textColor = .systemRed
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true  // 通常は非表示
        return label
    }()

    
    private func fetchGroupAndObserve() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // まずユーザー情報から groupId を取得
        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      let gid = data["groupId"] as? String else { return }

                self.groupId = gid
                SessionManager.shared.groupId = gid

                // → グループ名も取得してタイトル更新
                db.collection("groups")
                    .document(gid)
                    .getDocument { groupSnap, _ in
                        if let gdata = groupSnap?.data(),
                           let groupName = gdata["name"] as? String {
                            DispatchQueue.main.async {
                                self.familyLabel.text = "\(groupName)のお買い物リスト"
                            }
                        }
                    }

                // 既存のショップリスナー解除
                self.listener?.remove()

                // ショップリストを監視
                self.listener = FirestoreManager.shared.observeShops(in: gid) { shops in
                    self.shops = shops
                    self.expandedSections = Set(0..<shops.count)
                    self.tableView.reloadData()

                    // ここで各ショップのアイテムリスナーを登録
                    for shop in shops {
                        self.startItemsListener(for: shop)
                    }
                }

            }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        //        loadCheckStates()
        tableView.reloadData()
        fetchGroupAndObserve()
        print("画面初期化時のSessionManager.shared.groupId = \(SessionManager.shared.groupId ?? "nil or empty")")
        //        NotificationCenter.default.addObserver(self, selector: #selector(reloadShops), name: Notification.Name("shopsUpdate"), object: nil)
        
       locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        print("viewDidLoad shops count: \(shops.count)")
            for shop in shops {
                print("shop: \(shop.name), id: \(shop.id)")
            }
            
            print("groupId: \(self.groupId ?? "nil")")
            
            for shop in shops {
                startItemsListener(for: shop)
            }
        guard let groupId = SessionManager.shared.groupId else { return }
        let db = Firestore.firestore()

        db.collection("groups")
          .document(groupId)
          .collection("notifications")
          .addSnapshotListener { snapshot, error in
              guard let snapshot = snapshot else { return }
              for diff in snapshot.documentChanges {
                  if diff.type == .added {
                      let message = diff.document.data()["message"] as? String ?? ""
                      self.sendLocalNotification(message: message)
                  }
              }
          }
        


//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
//            granted, error in
//            if granted {
//                print("通知の許可OK!")
//            } else {
//                print("通知の許可がもらえませんでした")
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFloatingButton()
        checkAndAddPredictedItems()
        for shop in shops {
                autoAddFrequentItems(for: shop)
            }
        if let data = UserDefaults.standard.data(forKey: "shops") {
                                    if let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
                                        shops = decoded
                                    } else {
                                        print("デコードに失敗しました")
                                    }
                                } else {
                                    print("shopsデータが存在しません")
                                }
                                tableView.reloadData()
                        print("画面表示時のSessionManager.shared.groupId = \(SessionManager.shared.groupId ?? "nil or empty")")
                
                        fetchGroupAndObserve()

    }
    
    func autoAddFrequentItems(for shop: Shop) {
        for item in shop.items {
            if let avg = item.averageInterval,
               let last = item.purchaseHistory.last { // 最後に購入した日を取得
                let nextDate = Calendar.current.date(byAdding: .day, value: Int(avg), to: last)!
                if nextDate <= Date() && !item.isChecked {
                    // Firestoreに追加
                    FirestoreManager.shared.addItem(
                        to: SessionManager.shared.groupId!,
                        shopId: shop.id,
                            name: item.name,
                            price: item.price,
                            importance: item.importance,
                            detail: item.detail
                    ) { result in
                        switch result {
                        case .success(let id):
                            print("自動追加: \(item.name)")
                        case .failure(let error):
                            print("自動追加失敗: \(error)")
                        }
                    }
                }
            }
        }
    }


    
    private func setupFloatingButton() {
        let addButton = UIButton()
        addButton.backgroundColor = .systemBlue
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 30
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.3
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addButton.addTarget(self, action: #selector(addShopButtonTapped), for: .touchUpInside)
        
        // view に追加
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        view.bringSubviewToFront(addButton)
    }
    
    func sendLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "買い物リスト通知"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 即時通知
        )

        UNUserNotificationCenter.current().add(request)
    }


    
    //    @objc func reloadShops() {
    //        if let data = UserDefaults.standard.data(forKey: "shops"),
    //           let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
    //            shops = decoded
    //            tableView.reloadData()
    //            print("一覧に最新のshopsを反映したよ！")
    //        }
    //    }
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            for listener in itemsListener.values {
                listener.remove()
            }
            itemsListener.removeAll()
        }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addVC = segue.destination as? ItemAddViewController {
            addVC.shopListVC = self
        }
    }

    func calculateAverageInterval(from history: [Date]) -> Int {
        guard history.count >= 2 else { return 0 }
        var intervals: [Int] = []

        for i in 1..<history.count {
            let interval = Calendar.current.dateComponents([.day], from: history[i-1], to: history[i]).day ?? 0
            intervals.append(interval)
        }

        let sum = intervals.reduce(0, +)
        return sum / intervals.count
    }


    func predictNextPurchaseDate(from history: [Date], averageInterval: Double?) -> Date? {
        guard let lastDate = history.sorted().last else { return nil }
        let intervalDays = averageInterval ?? 7 // デフォルト1週間
        return Calendar.current.date(byAdding: .day, value: Int(intervalDays.rounded()), to: lastDate)
    }

    
    func checkAndAddPredictedItems() {
        for section in 0..<shops.count {
            var shop = shops[section]
            for row in 0..<shop.items.count {
                var item = shop.items[row]
                guard let nextDate = predictNextPurchaseDate(from: item.purchaseHistory, averageInterval: item.averageInterval) else { continue }

                // 今日が予定日
                if Calendar.current.isDateInToday(nextDate) {
                    // 自動追加
                    let now = Date()
                    item.purchaseHistory.append(now)
                    item.isAutoAdded = true
                    shop.items[row] = item
                    shops[section] = shop

                    // Firestore更新
                    FirestoreManager.shared.updateItem(groupId: groupId, shop: shop, item: item)

                    // 通知
                    sendLocalNotification(title: "自動追加", body: "\(item.name) がリストに自動追加されました")
                }
            }
        }
        tableView.reloadData()
    }
    
    func sendLocalNotification(title: String = "お知らせ", body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil) // 即時通知
        UNUserNotificationCenter.current().add(request)
    }

    func showShopList() {
        // navigationController の root か ShopListVC を探して push または pop
        if let shopListVC = navigationController?.viewControllers.first(where: { $0 is ShopListViewController }) {
            navigationController?.popToViewController(shopListVC, animated: true)
        } else {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            if let shopListVC = sb.instantiateViewController(identifier: "ShopListViewController") as? ShopListViewController {
                navigationController?.setViewControllers([shopListVC], animated: true)
            }
        }
    }

    
    func showAutoAddedItem(itemId: String) {
        // 該当アイテムを配列に追加済みなら
        if let shopIndex = shops.firstIndex(where: { $0.items.contains(where: { $0.id == itemId }) }),
           let rowIndex = shops[shopIndex].items.firstIndex(where: { $0.id == itemId }) {
            
            // ラベル表示
            autoAddedLabel.isHidden = false
            
            // 必要ならテーブルをスクロール
            tableView.scrollToRow(at: IndexPath(row: rowIndex, section: shopIndex), at: .top, animated: true)
        }
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        //        if let data = UserDefaults.standard.data(forKey: "shops") {
//        //            if let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
//        //                shops = decoded
//        //            } else {
//        //                print("デコードに失敗しました")
//        //            }
//        //        } else {
//        //            print("shopsデータが存在しません")
//        //        }
//        //        tableView.reloadData()
//        print("画面表示時のSessionManager.shared.groupId = \(SessionManager.shared.groupId ?? "nil or empty")")
//
//        fetchGroupAndObserve()
//        
//    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "ToShopAddView",
    //           let navVC = segue.destination as? UINavigationController,
    //           let addVC = navVC.topViewController as? ShopAddViewController {
    //            addVC.delegate = self
    //        }
    //    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未設定" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return shops.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // セクションヘッダーで店名を出しているなら「+1しない」→ items.count だけ返す
        let shop = shops[section]
            return shop.isExpanded ? shop.items.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let shop = shops[indexPath.section]

        // 念のための範囲ガード（落ちない保険）
        guard shop.items.indices.contains(indexPath.row) else {
            print("⚠️ row out of range: section \(indexPath.section), row \(indexPath.row), items.count \(shop.items.count)")
            return UITableViewCell()
        }

        let item = shop.items[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopListItemCell", for: indexPath) as? ShopListItemCell else {
            return UITableViewCell()
        }

        // データ設定
        cell.item = item
        cell.shopId = shop.id
        cell.groupId = self.groupId
        cell.isChecked = item.isChecked

        //  タグは使わない
        cell.section = indexPath.section
        cell.row = indexPath.row
        cell.delegate = self

        // 表示
        cell.nameLabel.text = item.name
        cell.detailLabel?.text = item.detail
        cell.deadlineLabel?.text = formatDate(item.deadline)
        cell.importance = item.importance

        cell.detailButton.tag = indexPath.section
        cell.detailButton.rowNumber = indexPath.row
        return cell
    }





    
    func fetchItems(for shop: Shop) {
        guard let gid = SessionManager.shared.groupId else { return }
        
        Firestore.firestore()
            .collection("groups")
            .document(gid)
            .collection("shops")
            .document(shop.id)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let snapshot = snapshot {
                                self.shops = self.shops.map { s in
                                    if s.id == shop.id {
                                        var updatedShop = s
                                        updatedShop.items = snapshot.documents.map { doc in
                                            Item.fromDictionary(doc.data(), id: doc.documentID)
                                        }
                                        return updatedShop
                                    } else {
                                        return s
                                    }
                                }
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
    }

    
    @objc func addShopButtonTapped() {
        guard let gid = groupId else { return }
        let mapVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(identifier: "ShopAddViewController") as! ShopAddViewController
        mapVC.groupId = gid
        navigationController?.pushViewController(mapVC, animated: true)
    }

    
    
    @IBAction func editPositionButtonTapped(_ sender: UIButton) {
        //        tableView.isEditing.toggle()
    }
    
    
    @objc func addItemButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let selectedShop = shops[index] // ← 選択されたお店
        
        if let itemAddVC = storyboard?.instantiateViewController(withIdentifier: "ItemAddViewController") as? ItemAddViewController {
            itemAddVC.selectedShopIndex = index
            itemAddVC.groupId = self.groupId            // ← groupIdを渡す
            itemAddVC.shopId = selectedShop.id          // ← 選択されたshopのIDを渡す
            //            itemAddVC.delegate = self
            
            navigationController?.pushViewController(itemAddVC, animated: true)
        }
    }
    
    
    //    func didAddItem(_ item: Item, toShopAt index: Int) {
    //        print("新しい商品作成: \(item)")
    //        shops[index].items.append(item)
    //        print("現在のお店の商品数: \(shops[index].items.count)")
    //        shops[index].isExpanded = true
    //
    //        if let encoded = try? JSONEncoder().encode(shops) {
    //            UserDefaults.standard.set(encoded, forKey: "shops")
    //        }
    //        tableView.reloadData()
    //    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let shopName = shops[indexPath.section].name
//        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        guard let totalVC = storyboard.instantiateViewController(withIdentifier: "TotalAmountViewController") as? TotalAmountViewController else {
//            print("TotalAmountViewControllerのインスタンス化に失敗")
//            return
//        }
//        
//        totalVC.shopName = shopName  // shopNameが[String]型であることを確認
//        
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let sceneDelegate = windowScene.delegate as? SceneDelegate,
//           let window = sceneDelegate.window {
//            
//            window.rootViewController = totalVC
//            UIView.transition(with: window,
//                              duration: 0.3,
//                              options: .transitionCrossDissolve,
//                              animations: nil,
//                              completion: nil)
//        }
//    }



    
    
    
    

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currentLocation = locations.last else { return }
            checkNearbyShops(currentLocation: currentLocation)
        }
    
    func checkNearbyShops(currentLocation: CLLocation) {
        guard let groupId = SessionManager.shared.groupId else { return }
        let db = Firestore.firestore()
        
        db.collection("groups")
          .document(groupId)
          .collection("shops")
          .getDocuments { snapshot, error in
              guard let snapshot = snapshot else { return }
              
              for doc in snapshot.documents {
                  let data = doc.data()
                  let shopName = data["name"] as? String ?? ""
                  let lat = data["latitude"] as? Double ?? 0
                  let lon = data["longitude"] as? Double ?? 0
                  let shopLocation = CLLocation(latitude: lat, longitude: lon)
                  
                  let distance = currentLocation.distance(from: shopLocation) // メートル
                  
                  // 例えば 100m以内なら通知
                  if distance < 100 {
                      self.notifyForUnpurchasedItems(shopId: doc.documentID, shopName: shopName)
                  }
              }
          }
    }
    
    func notifyForUnpurchasedItems(shopId: String, shopName: String) {
        guard let groupId = SessionManager.shared.groupId else { return }
        let db = Firestore.firestore()
        
        db.collection("groups")
          .document(groupId)
          .collection("shops")
          .document(shopId)
          .collection("items")
          .whereField("isChecked", isEqualTo: false) // 未購入のみ
          .getDocuments { snapshot, error in
              guard let snapshot = snapshot else { return }
              for doc in snapshot.documents {
                  let itemName = doc.data()["name"] as? String ?? ""
                  self.sendLocalNotification(message: "\(shopName)に\(itemName)が残っています！")
              }
          }
    }


    
    //            func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    //                guard let region = region as? CLCircularRegion else { return }
    //
    //                let shopName = region.identifier
    //
    //                // 対象のお店を探す
    //                if let shop = shops.first(where: { $0.name == shopName }) {
    //                    // チェックされてない（買ってない）商品があるか？
    //                    let hasUncheckedItems = shop.items.contains(where: { !$0.isChecked })
    //
    //                    if hasUncheckedItems {
    //                        // 通知を出す！
    //                        let content = UNMutableNotificationContent()
    //                        content.title = "\(shop.name)の近くです！"
    //                        content.body = "まだ買ってない商品がありますよ"
    //                        content.sound = .default
    //
    //                        let request = UNNotificationRequest(
    //                            identifier: UUID().uuidString,
    //                            content: content,
    //                            trigger: nil
    //                        )
    //
    //                        UNUserNotificationCenter.current().add(request)
    //                    } else {
    //                        print("\(shop.name)には買うものがなかったので通知なし！")
    //                    }
    //                }
    //            }
    
    
    
    
    func shopListItemCell(_ cell: ShopListItemCell, didTapCheckButtonFor item: Item) {
        // TotalAmountVC に渡す
        NotificationCenter.default.post(
            name: .didAddItemToTotalAmount,
            object: nil,
            userInfo: ["item": item]
        )
        
        // チェック済み状態にする（UIだけ）
        cell.checkButton.isSelected = true
    }

    //セクションヘッダーの表示（お店の名前＋ボタン）
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        
        let nameLabel = UILabel(frame: CGRect(x: 50, y: 10, width: 200, height: 40))
        nameLabel.text = shops[section].name
        headerView.addSubview(nameLabel)
        
        let toggleButton = UIButton(frame: CGRect(x: 0, y: 10, width: 70, height: 40))
        let imageName = shops[section].isExpanded ? "chevron.down" : "chevron.forward"
        toggleButton.setImage(UIImage(systemName: imageName), for: .normal)
        toggleButton.tintColor = .systemBlue
        toggleButton.tag = section
        toggleButton.addTarget(self, action: #selector(toggleItems(_:)), for: .touchUpInside)
        headerView.addSubview(toggleButton)
        
        let addItemButton = UIButton(type: .system)
        addItemButton.setTitle("＋", for: .normal)
        addItemButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        addItemButton.frame = CGRect(x: tableView.frame.width - 60, y: 10, width: 40, height: 40)
        addItemButton.tag = section
        addItemButton.addTarget(self, action: #selector(addItemButtonTapped(_:)), for: .touchUpInside)
        headerView.addSubview(addItemButton)
        
        return headerView
    }

    
    @objc func toggleItems(_ sender: UIButton) {
        let section = sender.tag
        shops[section].isExpanded.toggle()
        
        // 押されたボタンのアイコンだけ更新
        let imageName = shops[section].isExpanded ? "chevron.down" : "chevron.forward"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
        
        // そのセクションの rows を更新
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }


    
    @objc func detailButtonTapped(_ sender: DetailButton) {
        print("詳細ボタンが押された")
        let section = sender.tag
        let selectedShop = shops[section]
        let selectedRow = sender.rowNumber
        
        let selectedItem = shops[section].items[selectedRow]

        print("選ばれたお店名: \(selectedShop.name)")
        print("商品数: \(selectedShop.items.count)")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let itemListVC = storyboard.instantiateViewController(withIdentifier: "ItemListViewController") as? ItemListViewController {
            itemListVC.shops = self.shops
            itemListVC.item = selectedItem  // ← 商品データを渡す
            itemListVC.selectedShopIndex = section
            itemListVC.selectedItemIndex = selectedRow
            navigationController?.pushViewController(itemListVC, animated: true)
        } else {
            print("ItemListViewControllerが見つかりません")
        }
    }

    func startItemsListener(for shop: Shop) {
        print("startItemsListener called for shop: \(shop.name), id: \(shop.id)")
        guard let groupId = self.groupId else { return }

        let itemsRef = db.collection("groups")
                         .document(groupId)
                         .collection("shops")
                         .document(shop.id)
                         .collection("items")

        // リスナーを保持しておくと後で解除できる
        itemsListener[shop.id]?.remove()
        itemsListener[shop.id] = itemsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("アイテムリスナー取得失敗: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                    print("snapshot?.documents は nil です")
                    return
                }

                print("取得した items 数: \(documents.count)")
            documents.forEach { doc in
                do {
                    let item = try doc.data(as: Item.self)
                    print("デコード成功: \(item.name)")
                } catch {
                    print("デコード失敗: \(error)")
                }
            }


            let updatedItems: [Item] = documents.map { doc in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? ""
                let price = data["price"] as? Double ?? 0
                let isChecked = data["isChecked"] as? Bool ?? false
                let importance = data["importance"] as? Int ?? 1
                let detail = data["detail"] as? String ?? ""
                let requestedBy = data["requestedBy"] as? String ?? ""
                let deadline = (data["deadline"] as? Timestamp)?.dateValue()
                let purchasedDate = (data["purchasedDate"] as? Timestamp)?.dateValue()
                let buyerIds = data["buyerIds"] as? [String] ?? []

                return Item(
                    id: id,
                    shopId: shop.id,
                    
                    name: name,
                    price: price,
                    isChecked: isChecked,
                    importance: importance,
                    detail: detail,
                    deadline: deadline,
                    requestedBy: requestedBy,
                    buyerIds: buyerIds
                )
            }


                print("取得した items 数: \(updatedItems.count)")
                updatedItems.forEach { print($0.name) }

            if let index = self.shops.firstIndex(where: { $0.id == shop.id }) {
                self.shops[index].items = updatedItems
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }


        }
    }
    
    
    //    func saveCheckStates() {
    //        var checkStates: [[Bool]] = []
    //        for shop in shops {
    //            let itemStates = shop.items.map { $0.isChecked }
    //            checkStates.append(itemStates)
    //        }
    //        UserDefaults.standard.set(checkStates, forKey: "CheckStates")
    //    }
    //
    //    func loadCheckStates() {
    //        if let saveStates = UserDefaults.standard.array(forKey: "CheckStates") as? [[Bool]] {
    //            for (shopIndex, itemStates) in saveStates.enumerated() {
    //                if shopIndex < shops.count {
    //                    for (itemIndex, state) in itemStates.enumerated() {
    //                        shops[shopIndex].items[itemIndex].isChecked = state
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let shop = shops[indexPath.section]
            let item = shop.items[indexPath.row]

            guard let groupId = self.groupId else {
                print("groupId が nil です")
                return
            }

            Firestore.firestore()
                .collection("groups").document(groupId)
                .collection("shops").document(shop.id)
                .collection("items").document(item.id)
                .delete { error in
                    if let error = error {
                        print("Firestore 削除失敗: \(error)")
                    } else {
                        print("Firestore 削除成功")
                        // ローカルからも削除
                        self.shops[indexPath.section].items.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
        }

        }
        
    }



extension ShopListViewController: ShopListItemCellDelegate {

    // 1️⃣ チェックボタン押下
    func shopListItemCell(_ cell: ShopListItemCell, didToggleCheckAt section: Int, row: Int) {
        guard shops.indices.contains(section),
              shops[section].items.indices.contains(row) else {
            print("⚠️ invalid index: section \(section), row \(row)")
            return
        }

        var item = shops[section].items[row]
        item.isChecked.toggle()

        // ✅ 購入チェックがついたときに購入履歴を更新
        if item.isChecked {
            markItemAsPurchased(&item)
        }

        // ローカルの items を更新
        shops[section].items[row] = item
        let shop = shops[section]

        // Firestore 保存用の辞書
        let update: [String: Any] = [
            "isChecked": item.isChecked,
            "purchasedDate": item.isChecked ? Timestamp(date: Date()) : FieldValue.delete(),
            "purchaseHistory": item.purchaseHistory.map { Timestamp(date: $0) },
            "purchaseIntervals": item.purchaseIntervals,
            "averageInterval": item.averageInterval ?? 0
        ]

        Firestore.firestore()
            .collection("groups").document(groupId)
            .collection("shops").document(shop.id)
            .collection("items").document(item.id)
            .updateData(update) { error in
                if let error = error {
                    print("購入状態更新失敗: \(error)")
                } else {
                    print("購入状態更新成功！")
                }
            }

        tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
    }


    // 2️⃣ 価格変更
    func shopListItemCell(_ cell: ShopListItemCell, didUpdatePrice price: Double, section: Int, row: Int) {
        guard shops.indices.contains(section),
              shops[section].items.indices.contains(row) else { return }

        shops[section].items[row].price = price
        let item = shops[section].items[row]
        let shop = shops[section]

        let update: [String: Any] = ["price": price]
        Firestore.firestore()
            .collection("groups").document(groupId)
                .collection("shops")
                .document(shop.id)
                .collection("items")
                .document(item.id)
                .updateData(update) { error in
                if let error = error {
                    print("価格更新失敗: \(error)")
                }
            }

        tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
    }

    // 3️⃣ 詳細ボタン押下
    func shopListItemCell(_ cell: ShopListItemCell, didTapDetailFor item: Item) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ItemListViewController") as? ItemListViewController {
            vc.item = item
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func markItemAsPurchased(_ item: inout Item) {
        let today = Date()
        
        // 間隔計算
        if let lastDate = item.purchaseHistory.sorted().last {
            let interval = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if interval > 0 {
                item.purchaseIntervals.append(interval)
                let sum = item.purchaseIntervals.reduce(0, +)
                item.averageInterval = Double(sum) / Double(item.purchaseIntervals.count)
                item.averageInterval = (item.averageInterval! * 10).rounded() / 10 // 小数1桁
            }
        }
        
        
        item.purchaseHistory.append(today)
    }

}





//extension ShopListViewController: ShopAddViewControllerDelegate {
//    func didAddShop(name: String, latitude: Double, longitude: Double) {
//        let newShop = Shop(name: name, latitude: latitude, longitude: longitude, items: [], isExpanded: true)
//        shops.append(newShop)
//        tableView.reloadData()
//    }
//}

