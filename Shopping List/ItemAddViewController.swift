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
        
        guard let name = nameTextField.text, !name.isEmpty,
              let priceText = priceTextField.text,
              let price = Int(priceText),
              let detail = detailTextView.text,
              let selectedShopIndex = selectedShopIndex else {
            return
        }
        
        
        let deadline = deadlineDatePicker.date
        let importance = importanceSegment.selectedSegmentIndex
        
        let newItem = Item(name: name, price: price, deadline: deadline, detail: detail, importance: importance)
        
        delegate?.didAddItem(newItem, toShopAt: selectedShopIndex)
        
        dismiss(animated: true, completion: nil)
        }
    
    
    weak var delegate: ItemAddViewControllerDelegate?
    var selectedShopIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
}
    



