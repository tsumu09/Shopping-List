//
//  ItemCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/08.
//

import UIKit

class ItemCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    var importance: Int = 0 {
        didSet {
            switch importance {
            case 1:
                backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
            case 2:
                backgroundColor = UIColor.red.withAlphaComponent(0.3)
            default:
                backgroundColor = UIColor.white
            }
        }
    }
}
