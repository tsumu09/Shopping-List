//
//  MemberCell.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/27.
//

import UIKit

class MemberCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(with member: AppUser) {
        // firstName だけ表示
        nameLabel.text = member.displayName
    }

}
