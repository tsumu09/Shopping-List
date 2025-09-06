//
//  TotalAmountItemTableViewCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/18.
//

import UIKit
import FirebaseFirestore

protocol TotalAmountItemCellDelegate: AnyObject {
    func totalAmountItemCell(_ cell: TotalAmountItemCell, didUpdatePrice price: Double, section: Int, row: Int)
    func totalAmountItemCell(_ cell: TotalAmountItemCell, didToggleCheck section: Int, row: Int)
}



class TotalAmountItemCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var buyerLabel: UILabel!

    
    var item: Item?
    weak var delegate: TotalAmountItemCellDelegate?
       var section: Int!
       var row: Int!
    
  
    
    override func awakeFromNib() {
        super.awakeFromNib()
        priceTextField.delegate = self
    }
    
    func configure(with item: Item) {
        itemNameLabel.text = item.name
        priceTextField.text = "\(item.price)"

        // buyerIds が空なら空欄
        guard !item.buyerIds.isEmpty else {
            buyerLabel.text = ""
            return
        }

        let db = Firestore.firestore()
        var names: [String] = []
        
        // UID ごとに名前取得
        for uid in item.buyerIds {
            db.collection("users").document(uid).getDocument { snapshot, error in
                guard let data = snapshot?.data(), let firstName = data["firstName"] as? String else { return }

                names.append(firstName)

                // すべての UID の名前が揃ったら更新
                if names.count == item.buyerIds.count {
                    DispatchQueue.main.async {
                        self.buyerLabel.text = "購入者: " + names.joined(separator: ", ")
                    }
                }
            }
        }
    }



}
