//
//  Shop.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/06/05.
//

import Foundation
import FirebaseFirestore

struct Shop: Codable {
    var id: String = UUID().uuidString
    var name: String
    var latitude: Double
    var longitude: Double
    var items: [Item] = []
    var isExpanded: Bool = true

    var totalPrice: Double {
        return items.reduce(0) { $0 + $1.price }
    }
}
