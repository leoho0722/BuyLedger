//
//  SyncQueueItem.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation
import SwiftData

/// 失敗重送的本機待送佇列項目 (對齊 sync-failure-recovery)。離線/失敗時把寫入操作持久化，
/// 連線恢復或下次啟動時依序重送；重送以 ``opID`` + ``entityID`` 搭配後端 client UUID upsert
/// 與每欄位 HLC 達成冪等 (相同時鐘為 no-op)。本機專屬、不進生成型別。
@Model
final class SyncQueueItem {

    // MARK: - Data Properties

    /// 操作唯一 id (UUID 字串)。
    var opID: String

    /// 目標領域實體 id。
    var entityID: String

    /// 所屬 collection ("orders" / "campaigns")。
    var collection: String

    /// 操作型別 ("upsert" / "delete")。
    var opRaw: String

    /// 變更欄位，JSON of `[欄位名: 值]`。
    var changedFieldsJSON: String

    /// 每變更欄位的 HLC，JSON of `[欄位名: 編碼 HLC]`。
    var fieldClocksJSON: String

    /// 重試次數。
    var attempts: Int

    /// 入列時間 (由注入的 date 提供)。
    var enqueuedAt: Date

    // MARK: - Init

    /// 建立一筆待送佇列項目。
    /// - Parameters:
    ///   - opID: 操作唯一 id (UUID 字串)。
    ///   - entityID: 目標領域實體 id。
    ///   - collection: 所屬 collection ("orders" / "campaigns")。
    ///   - opRaw: 操作型別 ("upsert" / "delete")。
    ///   - changedFieldsJSON: 變更欄位的 JSON。
    ///   - fieldClocksJSON: 每變更欄位 HLC 的 JSON。
    ///   - attempts: 重試次數 (預設 0)。
    ///   - enqueuedAt: 入列時間 (由注入的 date 提供)。
    init(
        opID: String,
        entityID: String,
        collection: String,
        opRaw: String,
        changedFieldsJSON: String,
        fieldClocksJSON: String,
        attempts: Int = 0,
        enqueuedAt: Date
    ) {
        self.opID = opID
        self.entityID = entityID
        self.collection = collection
        self.opRaw = opRaw
        self.changedFieldsJSON = changedFieldsJSON
        self.fieldClocksJSON = fieldClocksJSON
        self.attempts = attempts
        self.enqueuedAt = enqueuedAt
    }
}
