//
//  ItemCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

protocol ItemCellDelegate: AnyObject {
    func didTapDetail(for item: Item)
}

class ItemCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
    weak var delegate: ItemCellDelegate?
    var item: Item?
    
    @IBAction func detailButtonTapped(_ sender: UIButton) {
        if let item = item {
            delegate?.didTapDetail(for: item)
        }
    }
}
