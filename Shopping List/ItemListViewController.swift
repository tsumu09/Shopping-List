//
//  ItemListViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

class ItemListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var priceTextField: UITextField!
    
    @IBOutlet weak var detailTextView: UITextView!
    
    @IBOutlet weak var importanceSegment: UISegmentedControl!
    
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    
    var shops: [Shop] = []
    var selectedShopIndex: Int?
    var selectedItemIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = UserDefaults.standard.data(forKey: "shops"),
            let decoded = try? JSONDecoder().decode([Shop].self, from: data) {
            shops = decoded
        }
        // 編集不可にする（あとでeditで切り替え）
        nameTextField.isEnabled = false
        priceTextField.isEnabled = false
        deadlineDatePicker.isEnabled = false
        detailTextView.isEditable = false
        importanceSegment.isEnabled = false
       
        if let shopIndex = selectedShopIndex,
           let itemIndex = selectedItemIndex {
            let item = shops[shopIndex].items[itemIndex]
            nameTextField.text = item.name
            priceTextField.text = String(item.price)
            deadlineDatePicker.date = item.deadline ?? Date()
            detailTextView.text = item.detail
            importanceSegment.selectedSegmentIndex = item.importance
        }

       
    }
    
    
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        print("保存ボタンが押されました！")
        
        guard let name = nameTextField.text, !name.isEmpty,
              let shopIndex = selectedShopIndex,
              let itemIndex = selectedItemIndex else {
            print("名前が未入力か、インデックスがnilです")
            return
        }

        let price = Int(priceTextField.text ?? "") ?? 0
           let detail = detailTextView.text ?? ""
           let deadline = deadlineDatePicker.date
           let importance = importanceSegment.selectedSegmentIndex

           // 更新！
           shops[shopIndex].items[itemIndex].name = name
           shops[shopIndex].items[itemIndex].price = price
           shops[shopIndex].items[itemIndex].detail = detail
           shops[shopIndex].items[itemIndex].deadline = deadline
           shops[shopIndex].items[itemIndex].importance = importance


        // UserDefaults に保存
        if let encoded = try? JSONEncoder().encode(shops) {
            UserDefaults.standard.set(encoded, forKey: "shops")
            // 保存後
            NotificationCenter.default.post(name: Notification.Name("shopsUpdated"), object: nil)
            print(" 編集内容をUserDefaultsに保存したよ！")
        } else {
            print(" エンコードに失敗したよ…")
        }

        // 一つ前の画面に戻る
        navigationController?.popViewController(animated: true)
        
    }
    
    weak var delegate: ItemAddViewControllerDelegate?
   
    
    var item: Item?

   

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        nameTextField.isEnabled = true
        priceTextField.isEnabled = true
        deadlineDatePicker.isEnabled = true
        detailTextView.isEditable = true
        importanceSegment.isEnabled = true
    }
    
    
}
