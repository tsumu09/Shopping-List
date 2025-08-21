//
//  TotalAmountShopTableViewCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/19.
//

import UIKit

class TotalAmountShopCell: UITableViewCell {
    
    // Storyboardで接続するIBOutlet
    @IBOutlet weak var shopNameLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    // セルの初期化処理
    override func awakeFromNib() {
        super.awakeFromNib()
        // ラベルの初期化やスタイル設定があればここで
        shopNameLabel.text = ""
        totalPriceLabel.text = "¥0"
    }
    
    // セルにショップ情報をセットするメソッド
    func configure(with shop: Shop) {
        shopNameLabel.text = shop.name
        
        let total = shop.items.reduce(0) { $0 + $1.price }
        totalPriceLabel.text = "¥\(total)"
    }
}
