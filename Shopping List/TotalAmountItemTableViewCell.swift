//
//  TotalAmountItemTableViewCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/18.
//

import UIKit

protocol TotalAmountItemCellDelegate: AnyObject {
    func TotalAmountItemCell(_ cell: TotalAmountItemCell, section: Int, row: Int)
}


class TotalAmountItemCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var priceTextField: UITextField!
    
    var item: Item?
    weak var delegate: TotalAmountItemCellDelegate?
       var section: Int!
       var row: Int!
    
  
    
    override func awakeFromNib() {
        super.awakeFromNib()
        priceTextField.delegate = self
    }
}
