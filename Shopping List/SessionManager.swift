//
//  SessionManager.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/08/11.
//

import Foundation

final class SessionManager {
    static let shared = SessionManager()
    private init() {}

    var groupId: String?
}
