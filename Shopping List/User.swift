//
//  User.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/27.
//

struct AppUser {
    var uid: String?
    var firstName: String
    var lastName: String
    var email: String?
    
    init(uid: String?, firstName: String, lastName: String, email: String?) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    init?(dictionary: [String: Any], uid: String) {
        guard let firstName = dictionary["first_name"] as? String,
              let lastName = dictionary["last_name"] as? String,
              let email = dictionary["email"] as? String else { return nil }
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
    
    // 🔹 追加：firstName だけで作れる簡易イニシャライザ
    init(uid: String?, firstName: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = ""
        self.email = nil
    }
}
