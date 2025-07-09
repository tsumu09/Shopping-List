//
//  FirestoreManager.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/07/09.
//

import Foundation
import FirebaseFirestore

final class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    private init() {}
    
    /// ユーザーの存在確認
    public func userExists(email: String, completion: @escaping (Bool) -> Void) {
        let safeEmail = Self.safeEmail(email)
        db.collection("users").document(safeEmail).getDocument { snapshot, error in
            guard error == nil else {
                print("Error checking user existence: \(error!.localizedDescription)")
                completion(false)
                return
            }
            completion(snapshot?.exists == true)
        }
        
    }
    
    
    public func insertUser(_ user: FirestoreUser, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(user.safeEmail).setData([
            "first_name": user.firstName,
            "last_name": user.lastName,
            "email": user.emailAddress
        ]) { error in
            if let error = error {
                print("Failed to insert user: \(error.localizedDescription)")
                completion(false)
            } else {
                print("User inserted successfully")
                completion(true)
            }
        }
    }
    
    static func safeEmail(_ email: String) -> String {
        return email.replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
    }
    
    struct FirestoreUser {
        let firstName: String
        let lastName: String
        let emailAddress: String
        var safeEmail: String {
            return FirestoreManager.safeEmail(emailAddress)
        }
    }
}
