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
    
    func configure(with item: Item, uidToDisplayName: [String: String]) {
        self.item = item  // セル内のプロパティにコピー
        
        itemNameLabel.text = item.name
        priceTextField.text = "\(item.price)"
        
        // buyerIds は絶対に変更しない
        let names: [String]
        
        if let cachedNames = item.buyerNames, !cachedNames.isEmpty {
            // 既にキャッシュがある場合はそれを使用
            names = cachedNames
        } else {
            // uidToDisplayName を使って名前を作成（非同期不要）
            names = item.buyerIds.map { uidToDisplayName[$0] ?? "不明" }
            // キャッシュとして保存
            self.item?.buyerNames = names
        }
        
        if names.isEmpty {
            buyerLabel.text = "購入者: 不明"
        } else {
            buyerLabel.text = "購入者: " + names.joined(separator: ", ")
        }
    }
}
