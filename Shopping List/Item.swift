//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import Foundation
import FirebaseFirestore

struct Item: Identifiable {
    var id: String
    var name: String
    var price: Double
    var isChecked: Bool = false
    var importance: Int
    var detail: String
    var deadline: Date?
    var requestedBy: String
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Item {
        let name = dict["name"] as? String ?? ""
        let price = dict["price"] as? Double ?? 0
        let isChecked = dict["isChecked"] as? Bool ?? false
        let importance = dict["importance"] as? Int ?? 0
        let detail = dict["detail"] as? String ?? ""
        let deadlineTimestamp = dict["deadline"] as? Timestamp
        let deadline = deadlineTimestamp?.dateValue()
        let requestedBy = dict["requestedBy"] as? String ?? ""
        
        return Item(
            id: id,
            name: name,
            price: price,
            isChecked: isChecked,
            importance: importance,
            detail: detail,
            deadline: deadline,
            requestedBy: requestedBy
        )
    }
}

//    init(name: String, price: Int, deadline: Date? = nil, detail: String, importance: Int, id: String, ) {
//        self.name = name
//        self.price = price
//        self.deadline = deadline
//        self.detail = detail
//        self.importance = importance
//    }





