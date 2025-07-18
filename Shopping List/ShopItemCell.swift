//
//  ItemCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit

protocol ShopItemCellDelegate: AnyObject {
    func didTapDetail(for item: Item)
}

class ShopItemCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var importanceLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    
    weak var delegate: ShopItemCellDelegate?
    var item: Item?
    
    var isChecked: Bool = false {
        didSet {
            updateCheckButton()
        }
    }
    var toggleCheckAction: (() -> Void)?
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        updateCheckButton()
//    }
    
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        toggleCheckAction?()
    }
    
    private func updateCheckButton() {
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        checkButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    var importance: Int = 0 {
        didSet {
            updateBackgroundColor()
        }
    }
    
    private func updateBackgroundColor() {
        switch importance {
        case 2:
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)// 高
        case 1:
            contentView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3) // 中
        default:
            contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3) // 低
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .white
    }
    
    @IBAction func detailButtonTapped(_ sender: UIButton) {
        if let item = item {
            delegate?.didTapDetail(for: item)
        }
    }
}
