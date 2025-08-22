//
//  TotalAmountItemTableViewCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/18.
//

import UIKit

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
}
