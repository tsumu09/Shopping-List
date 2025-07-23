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

class ShopListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, ItemAddViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var familyLabel: UILabel!
    
    var saveDate: UserDefaults = UserDefaults.standard

    var shops: [Shop] = []
    var groupId: String?
    var expandedSections: Set<Int> = []
    var listener: ListenerRegistration?
    var shopId: String?
    var selectedShopIndex: Int?
    weak var delegate: ItemAddViewControllerDelegate?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadCheckStates()
        tableView.reloadData()
        fetchGroupAndObserve()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadShops), name: Notification.Name("shopsUpdate"), object: nil)
        
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
    
    @objc func reloadShops() {
        if let data = UserDefaults.standard.data(forKey: "shops"),
           let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
            shops = decoded
            tableView.reloadData()
            print("一覧に最新のshopsを反映したよ！")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopItemCell", for: indexPath) as? ShopItemCell else{
                return UITableViewCell()
            }
            let item = shops[indexPath.section].items[indexPath.row]
            print("商品を表示中: \(item.name)")
            cell.nameLabel.text = item.name
            cell.isChecked = item.isChecked
            cell.detailLabel?.text = item.detail
            cell.deadlineLabel?.text = formatDate(item.deadline)
            cell.importance = item.importance
            
            cell.toggleCheckAction = { [weak self] in
                item.isChecked.toggle()
                cell.isChecked = item.isChecked
                self?.saveCheckStates()
            }
            
            cell.detailButton.tag = indexPath.section
            cell.detailButton.addTarget(self, action: #selector(detailButtonTapped(_:)), for: .touchUpInside)
            print("表示する商品名 : \(item.name)")
            return cell
        }
    
    @IBAction func addShopButtonTapped(_ sender: UIButton) {
////        let storyboard = UIStoryboard(name: "Main", bundle: nil)
////        if let shopAddVC = storyboard.instantiateViewController(withIdentifier: "ShopAddViewController") as? ShopAddViewController {
////            shopAddVC.delegate = self
////            navigationController?.pushViewController(shopAddVC, animated: true)
//        }
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
            itemAddVC.delegate = self
            
            navigationController?.pushViewController(itemAddVC, animated: true)
        }
    }

    
    func didAddItem(_ item: Item, toShopAt index: Int) {
        print("新しい商品作成: \(item)")
        shops[index].items.append(item)
        print("現在のお店の商品数: \(shops[index].items.count)")
        shops[index].isExpanded = true
        
        if let encoded = try? JSONEncoder().encode(shops) {
            UserDefaults.standard.set(encoded, forKey: "shops")
        }
        tableView.reloadData()
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
        let shop = shops[section]
        return shops[section].isExpanded ?  +shops[section].items.count : 0
    }
            
            func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
                guard let region = region as? CLCircularRegion else { return }

                let shopName = region.identifier

                // 対象のお店を探す
                if let shop = shops.first(where: { $0.name == shopName }) {
                    // チェックされてない（買ってない）商品があるか？
                    let hasUncheckedItems = shop.items.contains(where: { !$0.isChecked })

                    if hasUncheckedItems {
                        // 通知を出す！
                        let content = UNMutableNotificationContent()
                        content.title = "\(shop.name)の近くです！"
                        content.body = "まだ買ってない商品がありますよ🛒"
                        content.sound = .default

                        let request = UNNotificationRequest(
                            identifier: UUID().uuidString,
                            content: content,
                            trigger: nil
                        )

                        UNUserNotificationCenter.current().add(request)
                    } else {
                        print("\(shop.name)には買うものがなかったので通知なし！")
                    }
                }
            }
        
    
    private func fetchGroupAndObserve() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      let gid = data["groupId"] as? String else { return }
                
                self.groupId = gid
                self.expandedSections = Set(0..<self.shops.count)
                
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
                
                //  ここでリアルタイム監視開始！
                db.collection("groups")
                  .document(gid)
                  .collection("shops")
                  .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let documents = snapshot?.documents else { return }

                    var loadedShops: [Shop] = []
                    
                    let group = DispatchGroup()
                    
                    for doc in documents {
                        let data = doc.data()
                        let shopId = doc.documentID
                        let name = data["name"] as? String ?? ""
                        let latitude = data["latitude"] as? Double ?? 0.0
                        let longitude = data["longitude"] as? Double ?? 0.0
                        
                        var shop = Shop(name: name, latitude: latitude, longitude: longitude, items: [], isExpanded: true)
                        
                        group.enter()
                        db.collection("groups")
                          .document(gid)
                          .collection("shops")
                          .document(shopId)
                          .collection("items")
                          .addSnapshotListener { itemSnap, _ in
                              guard let itemDocs = itemSnap?.documents else {
                                  group.leave()
                                  return
                              }

                              shop.items = itemDocs.compactMap { itemDoc in
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
                              

                              loadedShops.append(shop)
                              group.leave()
                          }
                    }
                    
                    group.notify(queue: .main) {
                        self.shops = loadedShops
                        self.tableView.reloadData()
                    }
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
        toggleButton.setImage(UIImage(systemName: shops[section].isExpanded ? "chevron.down" : "chevron.forward"), for: .normal)
//        toggleButton.setTitleColor(.systemBlue, for: .normal)
        toggleButton.tag = section
        toggleButton.addTarget(self, action: #selector(toggleItems(_:)), for: .touchUpInside)
        headerView.addSubview(toggleButton)
        
        let addItemButton = UIButton(type: .system)
           addItemButton.setTitle("＋", for: .normal)  // または setImage にしてアイコンにもできる！
           addItemButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
           addItemButton.frame = CGRect(x: tableView.frame.width - 60, y: 10, width: 40, height: 40)
           addItemButton.tag = section  // どのセクションかを記録！
           addItemButton.addTarget(self, action: #selector(addItemButtonTapped(_:)), for: .touchUpInside)
           headerView.addSubview(addItemButton)
        
        return headerView
    }

    @objc func toggleItems(_ sender: UIButton) {
        let section = sender.tag
        shops[section].isExpanded.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
    @objc func detailButtonTapped(_ sender: UIButton) {
        print("詳細ボタンが押された")
        let section = sender.tag
        let selectedShop = shops[section]
        
            let indexPath = IndexPath(row: sender.accessibilityValue.flatMap { Int($0) } ?? 0, section: section)

            let selectedItem = shops[section].items[indexPath.row]  // -1はShopCellがrow 0のとき用
        
    
       
        print("選ばれたお店名: \(selectedShop.name)")
        print("商品数: \(selectedShop.items.count)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let itemListVC = storyboard.instantiateViewController(withIdentifier: "ItemListViewController") as? ItemListViewController {
            itemListVC.item = selectedItem
            itemListVC.selectedShopIndex = section
            itemListVC.selectedShopIndex = indexPath.section
            itemListVC.selectedItemIndex = indexPath.row
            navigationController?.pushViewController(itemListVC, animated: true)
        } else {
            print("ItemListViewControllerが見つかりません")
        }
    }
    
    
    
    func saveCheckStates() {
        var checkStates: [[Bool]] = []
        for shop in shops {
            let itemStates = shop.items.map { $0.isChecked }
            checkStates.append(itemStates)
        }
        UserDefaults.standard.set(checkStates, forKey: "CheckStates")
    }
    
    func loadCheckStates() {
        if let saveStates = UserDefaults.standard.array(forKey: "CheckStates") as? [[Bool]] {
            for (shopIndex, itemStates) in saveStates.enumerated() {
                if shopIndex < shops.count {
                    for (itemIndex, state) in itemStates.enumerated() {
                        shops[shopIndex].items[itemIndex].isChecked = state
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
                // ① モデル（shops配列）からアイテムを削除
                shops[indexPath.section].items.remove(at: indexPath.row)
                
                // ② UserDefaults に保存し直す
                if let encoded = try? JSONEncoder().encode(shops) {
                    UserDefaults.standard.set(encoded, forKey: "shops")
                }
                
                // ③ テーブルから行を削除
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }

        }

    
}
    
   
extension ShopListViewController: ShopAddViewControllerDelegate {
    func didAddShop(name: String, latitude: Double, longitude: Double) {
        let newShop = Shop(name: name, latitude: latitude, longitude: longitude, items: [], isExpanded: true)
        shops.append(newShop)
        tableView.reloadData()
    }
}

