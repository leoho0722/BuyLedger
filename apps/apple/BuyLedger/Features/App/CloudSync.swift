//
//  CloudSync.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

import FirebaseFirestore
import Foundation

/// iOS 端的 Firestore 同步進入點，對齊後端寫出的 `users/{uid}/…` per-user 投影。
///
/// 受 ``CloudSyncFeatureFlag`` 控制：旗標關閉 (預設) 時 App 不建立本物件、**完全不存取 Firestore**，一律走本機 SwiftData。旗標開啟且使用者登入後才建立，並以 `uid` 限縮在自己的子集合。
@MainActor
final class CloudSync {

    // MARK: - Sync Properties

    /// 目前登入使用者的 uid (資料歸屬鍵)。
    private let uid: String

    /// Firestore 實例。
    private let firestore: Firestore

    // MARK: - Init

    /// 以登入使用者的 uid 建立同步進入點。
    /// - Parameter uid: 目前登入使用者的 uid (資料歸屬鍵)。
    init(uid: String) {
        self.uid = uid
        self.firestore = Firestore.firestore()
    }

    // MARK: - References

    /// 使用者各自的根文件 `users/{uid}`。
    private var userDocument: DocumentReference {
        firestore.collection("users").document(uid)
    }

    /// 訂單即時投影集合 `users/{uid}/orders` (後端為唯一寫入方，client 只讀)。
    /// - Returns: 訂單即時投影集合的參照。
    func ordersCollection() -> CollectionReference {
        userDocument.collection("orders")
    }

    /// 開團即時投影集合 `users/{uid}/campaigns`。
    /// - Returns: 開團即時投影集合的參照。
    func campaignsCollection() -> CollectionReference {
        userDocument.collection("campaigns")
    }
}
