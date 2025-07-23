//
//  Shop.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/06/05.
//

import Foundation
import FirebaseFirestore

struct Shop: Codable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var items: [Item] = []
    var isExpanded: Bool

    init(id: String = UUID().uuidString, name: String, latitude: Double, longitude: Double, items: [Item], isExpanded: Bool) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.items = items
        self.isExpanded = isExpanded
    }
}
