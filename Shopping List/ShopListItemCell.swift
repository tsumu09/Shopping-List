//
//  ItemCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import FirebaseFirestore

protocol ShopListItemCellDelegate: AnyObject {
    func shopListItemCell(_ cell: ShopListItemCell, didToggleCheckAt section: Int, row: Int)
    func shopListItemCell(_ cell: ShopListItemCell, didUpdatePrice price: Double, section: Int, row: Int)
    func shopListItemCell(_ cell: ShopListItemCell, didTapDetailFor item: Item)
}


class ShopListItemCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var importanceLabel: UILabel!
    @IBOutlet weak var detailButton: DetailButton!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var deadlineLabel: UILabel!
    
    var item: Item!
    var shopId: String!
    var groupId: String?
    var shops: [Shop] = []
    var isChecked: Bool = false {
            didSet {
                updateCheckButton()
            }
        }
    var toggleCheckAction: (() -> Void)?
       var section: Int!
       var row: Int!
    weak var delegate: ShopListItemCellDelegate?
    
    let importanceView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // セル選択時の背景を透明に
        let bgView = UIView()
        bgView.backgroundColor = .clear
        selectedBackgroundView = bgView

        // チェックボタンのハイライト無効化（青くならないように）
        if var config = checkButton.configuration {
            config.showsActivityIndicator = false
            config.background.backgroundColor = .clear
            checkButton.configuration = config
        }
        checkButton.tintColor = .systemCyan
           detailButton.tintColor = .systemCyan
        // ボタンの画像の初期状態を設定
        updateCheckButton()
        
        
        contentView.addSubview(importanceView)
        importanceView.translatesAutoresizingMaskIntoConstraints = false
               // AutoLayout
        NSLayoutConstraint.activate([
            importanceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15), // 左端
            importanceView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 38), // toggleButton と同じ右端に合わせる
            importanceView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            importanceView.heightAnchor.constraint(equalToConstant: 42)
        ])
    }


    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        // セルの見た目を更新
        isChecked.toggle()
        updateCheckButton()
        
        // VC に「どのセルが押されたか」を伝える
        delegate?.shopListItemCell(self, didToggleCheckAt: section, row: row)
    }

    private func updateCheckButton() {
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        checkButton.setImage(UIImage(systemName: imageName), for: .normal)
        checkButton.isSelected = isChecked
    }

    
    func configure(with item: Item) {
        self.item = item
        self.isChecked = item.isChecked // Firestore の値を使う
        updateCheckButton()
        nameLabel.text = item.name
    }

    
    var importance: Int = 0 {
        didSet {
            configureImportance(level: importance)
        }
    }

    func configureImportance(level: Int) {
        switch level {
        case 3:
               // 低
            importanceView.backgroundColor = UIColor(red: 0.75, green: 0.90, blue: 0.75, alpha: 1.0)
           case 2:
               // 中
            importanceView.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.75, alpha: 1.0)
           default:
               // 高
            importanceView.backgroundColor = UIColor(red: 0.98, green: 0.80, blue: 0.80, alpha: 1.0)
           }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        updateCheckButton()             // UI を更新
        contentView.backgroundColor = .white
    }


    
    @IBAction func detailButtonTapped(_ sender: UIButton) {
        // item が存在するかチェック
        if let item = self.item {
               delegate?.shopListItemCell(self, didTapDetailFor: item)
           }
       }
}

extension Notification.Name {
    static let didAddItemToTotalAmount = Notification.Name("didAddItemToTotalAmount")
    static let didRemoveItemFromTotalAmount = Notification.Name("didRemoveItemFromTotalAmount")
}


class DetailButton: UIButton {
    var rowNumber: Int = 0
}
