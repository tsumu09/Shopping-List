//
//  Shop.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/06/05.
//

import Foundation

struct Shop: Codable {
    var name: String
    var latitude: Double
    var longitude: Double
    var items: [Item]
    var isExpanded: Bool

    init(name: String, latitude: Double, longitude: Double, items: [Item], isExpanded: Bool) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.items = items
        self.isExpanded = isExpanded
    }
}
