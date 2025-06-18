//
//  ItemAddViewController.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

protocol ItemAddViewControllerDelegate: AnyObject {
    func didAddItem(_ item: Item, toShopAt index: Int)
}

class ItemAddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var saveDate:UserDefaults = UserDefaults.standard
    
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
              let selectedShopIndex = selectedShopIndex else {
            print("名前が未入力か、selectedShopIndexがnilです")
            return
        }
        let priceText = priceTextField.text ?? ""
        let price = Int(priceText) ?? 0
        let detail = detailTextView.text ?? ""
        let deadline = deadlineDatePicker.date
        let importance = importanceSegment.selectedSegmentIndex
        
        let newItem = Item(name: name, price: price, deadline: deadline, detail: detail, importance: importance)
        
        print("新しい商品作成: \(newItem)")
        
        if let delegate = delegate {
            delegate.didAddItem(newItem, toShopAt: selectedShopIndex)
            print("delegateに渡しました")
        } else {
            print("delegateがnilです")
        }
        if let encoded = try? JSONEncoder().encode(newItem) {
            UserDefaults.standard.set(encoded, forKey: "items")
        }
        navigationController?.popViewController(animated: true)
    }
    
    weak var delegate: ItemAddViewControllerDelegate?
    var selectedShopIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
}
    



