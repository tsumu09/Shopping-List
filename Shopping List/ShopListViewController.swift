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

let locationManager = CLLocationManager()

class ShopListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var familyLabel: UILabel!
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        //        loadCheckStates()
        tableView.reloadData()
        fetchGroupAndObserve()
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(reloadShops), name: Notification.Name("shopsUpdate"), object: nil)
        
        Shopping_List.locationManager.delegate = self
        Shopping_List.locationManager.requestAlwaysAuthorization()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if granted {
                print("通知の許可OK!")
            } else {
                print("通知の許可がもらえませんでした")
            }
        }
    }
    
    //    @objc func reloadShops() {
    //        if let data = UserDefaults.standard.data(forKey: "shops"),
    //           let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
    //            shops = decoded
    //            tableView.reloadData()
    //            print("一覧に最新のshopsを反映したよ！")
    //        }
    //    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        if let data = UserDefaults.standard.data(forKey: "shops") {
        //            if let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
        //                shops = decoded
        //            } else {
        //                print("デコードに失敗しました")
        //            }
        //        } else {
        //            print("shopsデータが存在しません")
        //        }
        //        tableView.reloadData()
        print("画面表示時のSessionManager.shared.groupId = \(SessionManager.shared.groupId ?? "nil or empty")")

        fetchGroupAndObserve()
        
    }
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopItemCell", for: indexPath) as? ShopItemCell else {
            return UITableViewCell()
        }
        let shop = shops[indexPath.section]
        let item = shop.items[indexPath.row]

        print("商品を表示中: \(item.name)")

        cell.item = item
        cell.nameLabel.text = item.name
        cell.detailLabel?.text = item.detail
        cell.deadlineLabel?.text = formatDate(item.deadline)
        cell.importance = item.importance
        cell.priceTextField.text = String(format: "%.2f", item.price)

        // 🔹 delegate と位置情報を渡す
        cell.delegate = self
        cell.section = indexPath.section
        cell.row = indexPath.row

        // 🔹 delegateはShopItemCellが自分のUITextFieldDelegateを担当
        cell.priceTextField.delegate = cell

        // ボタン関連
        cell.detailButton.tag = indexPath.section
        cell.detailButton.rowNumber = indexPath.row
        cell.detailButton.addTarget(self, action: #selector(detailButtonTapped(_:)), for: .touchUpInside)

        print("表示する商品名 : \(item.name)")
        return cell
    }

    
    func fetchItems(for shop: Shop) {
        let groupId = self.groupId!
        Firestore.firestore()
            .collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shop.id)
            .collection("items")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("商品取得失敗: \(error)")
                    return
                }
                self.items = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Item.self)
                } ?? []
                self.tableView.reloadData()
            }
    }

    
    @IBAction func addShopButtonTapped(_ sender: UIButton) {
        guard let gid = groupId else { return }
        let mapVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(identifier: "ShopAddViewController")
        as! ShopAddViewController
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shopName = shops[indexPath.section].name
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let totalVC = storyboard.instantiateViewController(withIdentifier: "TotalAmountViewController") as? TotalAmountViewController else {
            print("TotalAmountViewControllerのインスタンス化に失敗")
            return
        }
        
        totalVC.shopName = shopName  // shopNameが[String]型であることを確認
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            window.rootViewController = totalVC
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
    }



    
    
    
    
    // セクションの数 = お店の数
    func numberOfSections(in tableView: UITableView) -> Int {
        return shops.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    // 各セクションに表示する商品の数（isExpandedで制御）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shops[section].isExpanded {
            return shops[section].items.count
        } else {
            return 0
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
                self.expandedSections = Set(0..<self.shops.count) // 初回ロード時は全セクション展開しておく
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
                
                // 既存のリスナー解除＆再登録
                self.listener?.remove()
                self.listener = FirestoreManager.shared
                    .observeShops(in: gid) { shops in
                        self.shops = shops
                        // shops の数が変わったら全展開または必要に応じてリセット
                        self.expandedSections = Set(0..<shops.count)
                        self.tableView.reloadData()
                    }
            }
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



extension ShopListViewController: ItemListViewControllerDelegate {
    func didUpdateItem(shopIndex: Int, itemIndex: Int, updatedItem: Item) {
        shops[shopIndex].items[itemIndex] = updatedItem
        tableView.reloadData()
    }
}

extension ShopListViewController: ShopItemCellDelegate {
    func shopItemCell(_ cell: ShopItemCell, didUpdatePrice price: Double, section: Int, row: Int) {
        shops[section].items[row].price = price

        let groupId = self.groupId!
        let shopId = shops[section].id
        let item = shops[section].items[row]

        let shop = shops[section]
        FirestoreManager.shared.updateItem(groupId: groupId, shop: shop, item: item) { error in
            if let error = error {
                print("価格更新失敗: \(error)")
            } else {
                print("価格更新成功")
            }
        }


        // 合計計算はしない
        let indexSet = IndexSet(integer: section)
        tableView.reloadSections(indexSet, with: .none)
    }


    
    func didTapDetail(for item: Item) {
        // 詳細画面遷移
    }
}


//extension ShopListViewController: ShopAddViewControllerDelegate {
//    func didAddShop(name: String, latitude: Double, longitude: Double) {
//        let newShop = Shop(name: name, latitude: latitude, longitude: longitude, items: [], isExpanded: true)
//        shops.append(newShop)
//        tableView.reloadData()
//    }
//}

