//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import Foundation
import FirebaseFirestore

class Item: Codable {
    var name: String
    var importance: Int
    var deadline: Date?
    var detail: String
    var price: Int
    var isChecked: Bool
    
    init(name: String, price: Int, deadline: Date? = nil, detail: String, importance: Int, isChecked: Bool = false) {
        self.name = name
        self.price = price
        self.deadline = deadline
        self.detail = detail
        self.importance = importance
        self.isChecked = isChecked
    }

}



