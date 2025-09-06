//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//
import Foundation
import FirebaseFirestore

struct Item: Codable, Identifiable {
    @DocumentID var id: String?            // Firestore の documentID
    var shopId: String
    var name: String
    var price: Double
    var isChecked: Bool = false
    var importance: Int
    var detail: String
    var deadline: Date?                     // Optional
    var requestedBy: String
    var buyerIds: [String] = []
    var purchaseIntervals: [Int] = []
    var averageInterval: Double?
    var purchaseHistory: [Date] = []
    var isAutoAdded: Bool = false
    var groupId: String

    // デフォルト値付きで、Firestore の欠けたフィールドも安全にデコード
    enum CodingKeys: String, CodingKey {
        case id
        case shopId
        case name
        case price
        case isChecked
        case importance
        case detail
        case deadline
        case requestedBy
        case buyerIds
        case purchaseIntervals
        case averageInterval
        case purchaseHistory
        case isAutoAdded
        case groupId
    }
}
extension Item {
    static func fromDictionary(_ data: [String: Any], id: String) -> Item {
        let rawIntervals = data["purchaseIntervals"] as? [Double] ?? []
        let intervals = rawIntervals.map { Int($0) }
        let deadline = (data["deadline"] as? Timestamp)?.dateValue()
        
        return Item(
            id: id,
            shopId: data["shopId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            price: data["price"] as? Double ?? 0,
            isChecked: data["isChecked"] as? Bool ?? false,
            importance: data["importance"] as? Int ?? 0,
            detail: data["detail"] as? String ?? "",
            deadline: deadline,
            requestedBy: data["requestedBy"] as? String ?? "",
            buyerIds: data["buyerIds"] as? [String] ?? [],
            purchaseIntervals: intervals,
            averageInterval: data["averageInterval"] as? Double ?? 0,
            isAutoAdded: false,
            groupId: data["groupId"] as? String ?? ""
        )
    }

}
