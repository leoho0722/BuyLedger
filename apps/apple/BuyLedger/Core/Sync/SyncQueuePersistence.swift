//
//  SyncQueuePersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation
import SwiftData

/// 失敗重送的本機待送佇列 (``SyncQueueItem``) 的背景 actor CRUD。與 ``OrderPersistence`` 共用
/// ``PersistenceContainer/shared``；推送失敗時 enqueue、恢復連線後 drain 重送、成功即 delete
@ModelActor
actor SyncQueuePersistence {

    // MARK: - View Method

    /// 入列一筆待送操作 (在 actor 內建構 @Model，避免跨邊界傳遞非 Sendable 型別)
    /// - Parameters:
    ///   - opID: 操作唯一 id (UUID 字串)
    ///   - entityID: 目標領域實體 id
    ///   - collection: 所屬 collection ("orders" / "campaigns")
    ///   - opRaw: 操作型別 ("upsert" / "delete")
    ///   - changedFieldsJSON: 變更欄位的 JSON
    ///   - fieldClocksJSON: 每變更欄位 HLC 的 JSON
    ///   - enqueuedAt: 入列時間 (由注入的 date 提供)
    func enqueue(
        opID: String,
        entityID: String,
        collection: String,
        opRaw: String,
        changedFieldsJSON: String,
        fieldClocksJSON: String,
        enqueuedAt: Date
    ) throws {
        let item = SyncQueueItem(
            opID: opID,
            entityID: entityID,
            collection: collection,
            opRaw: opRaw,
            changedFieldsJSON: changedFieldsJSON,
            fieldClocksJSON: fieldClocksJSON,
            enqueuedAt: enqueuedAt
        )
        modelContext.insert(item)
        try modelContext.save()
    }

    /// 讀出全部待送項目的 Sendable 投影 (依入列時間)
    /// - Returns: 依入列時間排序的待送項目投影陣列
    func all() throws -> [QueuedPush] {
        let items = try modelContext.fetch(
            FetchDescriptor<SyncQueueItem>(sortBy: [SortDescriptor(\.enqueuedAt)])
        )
        return items.map {
            QueuedPush(
                opID: $0.opID,
                entityID: $0.entityID,
                changedFieldsJSON: $0.changedFieldsJSON,
                fieldClocksJSON: $0.fieldClocksJSON
            )
        }
    }

    /// 待送筆數
    /// - Returns: 目前待送佇列中的項目數
    func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<SyncQueueItem>())
    }

    /// 依 opID 刪除 (重送成功後)
    /// - Parameter opID: 要刪除的操作唯一 id
    func delete(opID: String) throws {
        let descriptor = FetchDescriptor<SyncQueueItem>(
            predicate: #Predicate { $0.opID == opID }
        )
        for item in try modelContext.fetch(descriptor) {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}

// MARK: - Nested Types

extension SyncQueuePersistence {

    /// 待送項目的 Sendable 投影 (``SyncQueueItem`` 為 @Model 非 Sendable，跨 actor 邊界以此傳遞)
    struct QueuedPush: Sendable {

        /// 操作的唯一識別碼 (用於 dedupe 與重送成功後刪除)
        let opID: String

        /// 對應領域實體的 stable id
        let entityID: String

        /// 變更欄位的 JSON 編碼
        let changedFieldsJSON: String

        /// 各欄位邏輯時鐘 (field clock) 的 JSON 編碼
        let fieldClocksJSON: String
    }
}
