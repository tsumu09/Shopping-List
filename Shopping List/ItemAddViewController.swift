//
//  ItemAddViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol ItemAddViewControllerDelegate: AnyObject {
    func didAddItem(_ item: Item, toShopAt index: Int)
}

class ItemAddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var saveDate:UserDefaults = UserDefaults.standard
    var shops: [Shop] = []
    var groupId: String!
    var shopId: String!
    
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker,animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var priceTextField: UITextField!
    
    @IBOutlet weak var detailTextView: UITextView!
    
    @IBOutlet weak var importanceSegment: UISegmentedControl!
    
    @IBOutlet weak var deadlineDatePicker: UIDatePicker!
    
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        print("保存ボタンが押されました！")

        guard let name = nameTextField.text, !name.isEmpty,
              let price = String(priceTextField).text,
             
              let selectedShopIndex = selectedShopIndex,
              let groupId = self.groupId,
              let shopId = self.shopId else {
            print("入力不備（name / selectedShopIndex / groupId / shopId）")
            return
        }

        // Firestoreに保存
        FirestoreManager.shared.addItem
        (to: groupId, shopId: shopId, name: name, price: price, importance: importace, detail: detail) { result in
            switch result {
            case .success():
                print("Firestoreにアイテムを保存しました")
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                print("Firestore保存失敗: \(error.localizedDescription)")
            }
        }
        // 前の画面に戻る
        navigationController?.popViewController(animated: true)
    }

    
    weak var delegate: ItemAddViewControllerDelegate?
    var selectedShopIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
    



