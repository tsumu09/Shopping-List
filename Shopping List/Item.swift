//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import Foundation

class Item {
    var name: String
    var importance: Int
    var deadline: Date?
    var detail: String
    var price: Int
    
    init(name: String, price: Int, deadline: Date, detail: String, importance: Int) {
        self.name = name
        self.price = price
        self.deadline = deadline
        self.detail = detail
        self.importance = importance
    }
    
    struct Item {
        let name: String
        let price: Int
        let date: Date
        let detail: String
        let priority: Int
    }

}

struct Shop {
    var name: String
    var latitude: Double
    var longitude: Double
    var items: [Item] = []
    var isExpanded: Bool = false
}

