//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import Foundation
import FirebaseFirestore

struct Item: Codable, Identifiable {
    var id: String
    var name: String
    var price: Double
    var isChecked: Bool = false
    var importance: Int
    var detail: String
    var deadline: Date?
    var requestedBy: String
    var purchasedDate: Date?
    var buyerIds: [String] = []
    
    // Firestore の Dictionary から生成するメソッド
    static func fromDictionary(_ dict: [String: Any], id: String) -> Item {
        let name = dict["name"] as? String ?? ""
        let price = dict["price"] as? Double ?? 0
        let isChecked = dict["isChecked"] as? Bool ?? false
        let importance = dict["importance"] as? Int ?? 0
        let detail = dict["detail"] as? String ?? ""
        let deadlineTimestamp = dict["deadline"] as? Timestamp
        let deadline = deadlineTimestamp?.dateValue()
        let requestedBy = dict["requestedBy"] as? String ?? ""
        let purchasedTimestamp = dict["purchasedDate"] as? Timestamp
        let purchasedDate = purchasedTimestamp?.dateValue()
        let buyerIds = dict["buyerIds"] as? [String] ?? []

        return Item(
            id: id,
            name: name,
            price: price,
            isChecked: isChecked,
            importance: importance,
            detail: detail,
            deadline: deadline,
            requestedBy: requestedBy,
            purchasedDate: purchasedDate,
            buyerIds: buyerIds
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





