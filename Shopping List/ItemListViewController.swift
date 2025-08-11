//
//  ItemListViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol ItemListViewControllerDelegate: AnyObject {
    func didUpdateItem(shopIndex: Int, itemIndex: Int, updatedItem: Item)
}

class ItemListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var priceTextField: UITextField!
    
    @IBOutlet weak var detailTextView: UITextView!
    
    @IBOutlet weak var importanceSegment: UISegmentedControl!
    
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    
    var shops: [Shop] = []
    var selectedShopIndex: Int?
    var selectedItemIndex: Int?
    var item: Item?
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
           super.viewDidLoad()

           // 受け取った商品データをTextFieldに反映
           if let item = item {
               nameTextField.text = item.name
               priceTextField.text = "\(item.price)"
               print("ItemListViewController 表示時の groupId: \(SessionManager.shared.groupId ?? "nil or empty")")

           }
       }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        if let data = UserDefaults.standard.data(forKey: "shops"),
//            let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
//            shops = decoded
//        }
//        // 編集不可にする（あとでeditで切り替え）
//        nameTextField.isEnabled = false
//        priceTextField.isEnabled = false
//        deadlineDatePicker.isEnabled = false
//        detailTextView.isEditable = false
//        importanceSegment.isEnabled = false
//       
//        if let shopIndex = selectedShopIndex,
//           let itemIndex = selectedItemIndex {
//            let item = shops[shopIndex].items[itemIndex]
//            nameTextField.text = item.name
//            priceTextField.text = String(item.price)
//            deadlineDatePicker.date = item.deadline ?? Date()
//            detailTextView.text = item.detail
//            importanceSegment.selectedSegmentIndex = item.importance
//        }
//
//       
//    }
//
//
//    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        print("保存ボタンが押されました！")

        guard let name = nameTextField.text, !name.isEmpty,
              let shopIndex = selectedShopIndex,
              let itemIndex = selectedItemIndex else {
            print("selectedShopIndex または selectedItemIndex がnilです")
            return
        }

        print("selectedShopIndex = \(shopIndex), selectedItemIndex = \(itemIndex)")
        print("shops.count = \(shops.count)")

        if shops.indices.contains(shopIndex) {
            print("shops[\(shopIndex)].items.count = \(shops[shopIndex].items.count)")
        } else {
            print("shopIndexが配列の範囲外です")
        }

        // 範囲チェック
        guard shops.indices.contains(shopIndex),
              shops[shopIndex].items.indices.contains(itemIndex) else {
            print("インデックスが範囲外です")
            return
        }

        let price = Int(priceTextField.text ?? "") ?? 0
        let detail = detailTextView.text ?? ""
        let deadline = deadlineDatePicker.date
        let importance = importanceSegment.selectedSegmentIndex

        // 更新
        shops[shopIndex].items[itemIndex].name = name
        shops[shopIndex].items[itemIndex].price = price
        shops[shopIndex].items[itemIndex].detail = detail
        shops[shopIndex].items[itemIndex].deadline = deadline
        shops[shopIndex].items[itemIndex].importance = importance

        let updatedShop = shops[shopIndex]
           let updatedItem = shops[shopIndex].items[itemIndex]
        print("保存時の groupId: \(SessionManager.shared.groupId ?? "nil or empty")")
        
//        guard let groupId = SessionManager.shared.groupId, !groupId.isEmpty else {
//            print("Error: groupIdが未設定です。Firestore更新を中止します。")
//            return
//        }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                if let data = snapshot?.data(),
                    let gid = data["groupId"] as? String{
                    FirestoreManager.shared.updateItem(
                        groupId: gid,
                        shop: updatedShop,
                        item: updatedItem
                    ) { error in
                        if error == nil {
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            print(error)
                        }
                }
            }
        
       
        }

        
        // 一つ前の画面に戻る
//        navigationController?.popViewController(animated: true)
    }

//    
//    weak var delegate: ItemAddViewControllerDelegate?
//   
//
//
//   
//
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        nameTextField.isEnabled = true
        priceTextField.isEnabled = true
        deadlineDatePicker.isEnabled = true
        detailTextView.isEditable = true
        importanceSegment.isEnabled = true
    }
    

    // 編集画面内
    weak var delegate: ItemListViewControllerDelegate?

    
}
