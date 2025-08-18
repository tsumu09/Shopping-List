//
//  ShopCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

class ShopCell: UITableViewCell {
    @IBOutlet weak var shopNameLabel: UILabel!
    @IBOutlet weak var addItemButton: UIButton!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(shop: Shop) {
           shopNameLabel.text = shop.name
           totalPriceLabel.text = "合計: \(Int(shop.totalPrice))円"
       }
    
}
