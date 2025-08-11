//
//  Item.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/05/07.
//

import Foundation
import FirebaseFirestore

struct Item{
    var name: String
    var importance: Int
    var deadline: Date?
    var detail: String
    var price: Double
    var id: String
    var requestedBy: String
    
//    init(name: String, price: Int, deadline: Date? = nil, detail: String, importance: Int, id: String, ) {
//        self.name = name
//        self.price = price
//        self.deadline = deadline
//        self.detail = detail
//        self.importance = importance
//    }

}



