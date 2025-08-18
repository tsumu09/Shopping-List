//
//  ItemCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import UIKit
import FirebaseFirestore

protocol ShopListItemCellDelegate: AnyObject {
    func shopListItemCell(_ cell: ShopListItemCell, didTapCheckButtonFor item: Item)
    func didTapDetail(for item: Item)
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
    var isChecked: Bool = false {
            didSet {
                updateCheckButton()
            }
        }
    var toggleCheckAction: (() -> Void)?
    weak var delegate: ShopListItemCellDelegate?
       var section: Int!
       var row: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        updateCheckButton()
    }
   
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        guard let item = self.item, let shopId = self.shopId else { return }
        guard let groupId = self.groupId else { return }
        
        isChecked.toggle()
        updateCheckButton()
        delegate?.shopListItemCell(self, didTapCheckButtonFor: item)

        
        // Firestore に反映
        let itemRef = Firestore.firestore()
            .collection("groups")
            .document(groupId)
            .collection("shops")
            .document(shopId)
            .collection("items")
            .document(item.id)

        itemRef.updateData(["isChecked": isChecked]) { error in
            if let error = error {
                print("チェック状態更新失敗: \(error)")
            } else {
                print("チェック状態更新成功")
            }
        }

        // 通知で TotalAmountVC に送信
        if isChecked {
            NotificationCenter.default.post(
                name: .didAddItemToTotalAmount,
                object: nil,
                userInfo: ["shopId": shopId, "itemId": item.id]
            )
        } else {
                // チェック外したら TotalAmountVC からも削除する場合はここ
                NotificationCenter.default.post(
                    name: .didRemoveItemFromTotalAmount,
                    object: nil,
                    userInfo: ["shopId": shopId, "itemId": item.id]
                )
            }

            print("chekbuttonが押されました")
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
        updateCheckButton()             // UI を更新
        contentView.backgroundColor = .white
    }


    
    @IBAction func detailButtonTapped(_ sender: UIButton) {
        if let item = item {
            delegate?.didTapDetail(for: item)
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
