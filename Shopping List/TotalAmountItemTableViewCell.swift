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

        if item.buyerIds.isEmpty {
            buyerLabel.text = ""
        } else {
            let db = Firestore.firestore()
            var names: [String] = []
            let group = DispatchGroup()

            for uid in item.buyerIds {
                group.enter()
                db.collection("users").document(uid).getDocument { snapshot, error in
                    if let data = snapshot?.data(),
                       let name = data["displayName"] as? String {
                        names.append(name)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.buyerLabel.text = "購入者: " + names.joined(separator: ", ")
            }
        }
    }

}
