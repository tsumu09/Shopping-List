//
//  NotificationManager.swift
//  Shopping List
//
//  Created by 高橋紬季 on 2025/09/07.
//

import Foundation
import FirebaseFirestore
import UserNotifications
import FirebaseAuth

final class NotificationManager {

    static let shared = NotificationManager()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() { }

    func startObservingNotifications(groupId: String) {
        // 前回の監視を解除
        listener?.remove()

        listener = db.collection("groups")
            .document(groupId)
            .collection("notifications")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }

                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let data = change.document.data()
                        if let message = data["message"] as? String {
                            // フォアグラウンドなら即時通知
                            self.sendLocalNotification(message: message)
                        }
                    }
                }
            }
    }

    private func sendLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "お買い物アプリ"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // nil=即時通知（フォアグラウンドのみ）
        )

        UNUserNotificationCenter.current().add(request)
    }

    func stopObserving() {
        listener?.remove()
        listener = nil
    }
}
