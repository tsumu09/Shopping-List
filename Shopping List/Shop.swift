//
//  Shop.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/06/05.
//

import Foundation
import FirebaseFirestore

struct Shop {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var items: [Item] = []
    var isExpanded: Bool = false
    
    var totalPrice: Double {
           return items.reduce(0) { $0 + $1.price }
       }

    init(id: String = UUID().uuidString, name: String, latitude: Double, longitude: Double, items: [Item]) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.items = items
        
    }
}
