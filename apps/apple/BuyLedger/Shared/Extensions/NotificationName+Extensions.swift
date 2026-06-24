//
//  NotificationName+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation

extension Notification.Name {

    // MARK: - Static Properties

    /// 本機單筆訂單儲存後發出 (userInfo `order`)，供 ``CloudSyncEngine`` diff 後推送變更欄位
    static let buyLedgerOrderSaved = Notification.Name("buyLedgerOrderSaved")

    /// 本機批次儲存 / 合併 / cascade 改名後發出，供 ``CloudSyncEngine`` 重新比對所有本機訂單並推送變更
    static let buyLedgerOrdersResyncNeeded = Notification.Name("buyLedgerOrdersResyncNeeded")

    /// 本機訂單刪除後發出 (userInfo `id`)，供 ``CloudSyncEngine`` 推送刪除 (後端硬刪 + Firestore tombstone)
    static let buyLedgerOrderDeleted = Notification.Name("buyLedgerOrderDeleted")
}
