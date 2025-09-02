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
    var buyerIds: [String] = []
    var purchaseIntervals: [Int] = []        // 購入間隔（日数）
    var averageInterval: Double?             // 平均購入間隔（日数、小数あり）
    var purchaseHistory: [Date] = []         // 過去の購入履歴
    var isAutoAdded: Bool = false
    
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
        let buyerIds = dict["buyerIds"] as? [String] ?? []

        // Firestore に保存されている purchaseHistory
        let historyTimestamps = dict["purchaseHistory"] as? [Timestamp] ?? []
        let purchaseHistory = historyTimestamps.map { $0.dateValue() }

        // Firestore に保存されている購入間隔
        let purchaseIntervals = dict["purchaseIntervals"] as? [Int] ?? []
        let averageInterval = dict["averageInterval"] as? Double

        return Item(
            id: id,
            name: name,
            price: price,
            isChecked: isChecked,
            importance: importance,
            detail: detail,
            deadline: deadline,
            requestedBy: requestedBy,
            buyerIds: buyerIds,
            purchaseIntervals: purchaseIntervals,
            averageInterval: averageInterval,
            purchaseHistory: purchaseHistory
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





