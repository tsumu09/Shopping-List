//
//  User.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/27.
//

struct AppUser {
    var uid: String?
    var displayName: String
    var email: String?
    
    init(uid: String?, displayName: String, email: String?) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
    }
    
    init?(dictionary: [String: Any], uid: String) {
        guard let displayName = dictionary["displayName"] as? String,
              let email = dictionary["email"] as? String else { return nil }
        self.uid = uid
        self.displayName = displayName
        self.email = email
    }
    
    init(uid: String?, displayName: String) {
        self.uid = uid
        self.displayName = displayName
        self.email = nil
    }
}
