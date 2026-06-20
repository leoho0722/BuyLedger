//
//  OrderPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// SwiftData 上對訂單做 CRUD 的背景 actor。
///
/// 採用 `@ModelActor`，由 SwiftData 自動把 actor 綁到專屬 context，避免 `ModelContext` 跨執行緒造成的安全問題；領域層的 `LedgerOrder` 與持久層的 `OrderRecord` 在 actor 內互轉。
@ModelActor
actor OrderPersistence {

    // MARK: - View Method

    /// 讀出全部訂單，依日期由新到舊排序。
    /// - Returns: 領域型別陣列。
    func fetchAll() throws -> [LedgerOrder] {
        let descriptor = FetchDescriptor<OrderRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)

        return records.map { $0.toDomain() }
    }

    /// 寫入或更新單筆訂單。
    /// - Parameter order: 來源領域訂單。
    func upsert(_ order: LedgerOrder) throws {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(order)
        } else {
            modelContext.insert(OrderRecord(order: order))
        }

        try modelContext.save()
    }

    /// 以單一 `save()` 寫入或更新多筆訂單 (依 id upsert)，達成批次原子落盤。
    ///
    /// 供「多選批次更改狀態」使用：先一次讀出既有紀錄建索引，逐筆 apply 或 insert，最後單次 `save()`——
    /// 任一步失敗整批不生效，避免逐筆 `upsert` 的多次落盤與部分成功。
    /// - Parameter orders: 要寫入或更新的訂單；空陣列為 no-op。
    func upsertAll(_ orders: [LedgerOrder]) throws {
        guard !orders.isEmpty else { return }

        let existing = try modelContext.fetch(FetchDescriptor<OrderRecord>())
        var recordByID: [String: OrderRecord] = [:]
        for record in existing {
            recordByID[record.id] = record
        }

        for order in orders {
            if let record = recordByID[order.id] {
                record.apply(order)
            } else {
                modelContext.insert(OrderRecord(order: order))
            }
        }

        try modelContext.save()
    }

    /// 刪除指定 id 的訂單；若不存在不視為錯誤。
    /// - Parameter id: 要刪除的訂單編號。
    func delete(id: LedgerOrder.ID) throws {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    /// 把所有以 `oldName` 為訂單來源的訂單，更名為 `newName`。
    /// - Parameters:
    ///   - oldName: 原本的訂單來源名稱。
    ///   - newName: 新的訂單來源名稱。
    func renameOrderSource(from oldName: String, to newName: String) throws {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.orderSource == oldName }
        )
        for record in try modelContext.fetch(descriptor) {
            record.orderSource = newName
        }
        try modelContext.save()
    }

    /// 把所有類別清單包含 `oldName` 的訂單，於陣列內逐元素更名為 `newName`。
    ///
    /// `categories` 為複合 (陣列) attribute，SQLite store 不支援以 `#Predicate` 對其做 contains 查詢，故改為全量讀出後在記憶體過濾；cascade rename 屬低頻操作，成本可接受。
    /// - Parameters:
    ///   - oldName: 原本的類別名稱。
    ///   - newName: 新的類別名稱。
    func renameCategory(from oldName: String, to newName: String) throws {
        let records = try modelContext.fetch(FetchDescriptor<OrderRecord>())
        for record in records where record.categories.contains(oldName) {
            record.categories = record.categories.map { $0 == oldName ? newName : $0 }
        }
        try modelContext.save()
    }

    /// 把所有以 `oldName` 為付款方式的訂單，更名為 `newName`。
    /// - Parameters:
    ///   - oldName: 原本的名稱。
    ///   - newName: 新的名稱。
    func renamePaymentMethod(from oldName: String, to newName: String) throws {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        for record in try modelContext.fetch(descriptor) {
            record.paymentMethod = newName
        }
        try modelContext.save()
    }

    /// 把所有以 `oldName` 為對帳狀態的訂單，更名為 `newName`。
    /// - Parameters:
    ///   - oldName: 原本的對帳狀態名稱。
    ///   - newName: 新的對帳狀態名稱。
    func renameVerificationStatus(from oldName: String, to newName: String) throws {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.verificationStatus == oldName }
        )
        for record in try modelContext.fetch(descriptor) {
            record.verificationStatus = newName
        }
        try modelContext.save()
    }

    /// 把所有開團清單包含 `oldName` 的訂單，於陣列內逐元素更名為 `newName` (開團 cascade rename)。
    ///
    /// 與 ``renameCategory(from:to:)`` 相同，陣列 attribute 不支援 `#Predicate` contains 查詢，改為全量讀出後在記憶體過濾。
    /// - Parameters:
    ///   - oldName: 原本的開團名稱。
    ///   - newName: 新的開團名稱。
    func renameCampaign(from oldName: String, to newName: String) throws {
        let records = try modelContext.fetch(FetchDescriptor<OrderRecord>())
        for record in records where record.campaignNames.contains(oldName) {
            record.campaignNames = record.campaignNames.map { $0 == oldName ? newName : $0 }
        }
        try modelContext.save()
    }

    /// 以單一交易完成「寫入合併後新訂單 + 將來源訂單狀態改為已合併」。
    ///
    /// 新訂單 upsert 與來源訂單的狀態變更在同一次 `save()` 落盤——任一步失敗時整批不生效，避免中途失敗造成「新單已存在但舊單未轉已合併」的半合併狀態。
    /// - Parameters:
    ///   - newOrder: 合併後的新訂單 (含 ``LedgerOrder/mergedSourceIDs``)。
    ///   - consumedIDs: 被合併的來源訂單編號。
    func mergeOrders(newOrder: LedgerOrder, consumedIDs: [LedgerOrder.ID]) throws {
        let newID = newOrder.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == newID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(newOrder)
        } else {
            modelContext.insert(OrderRecord(order: newOrder))
        }

        let ids = Set(consumedIDs)
        let records = try modelContext.fetch(FetchDescriptor<OrderRecord>())
        for record in records where ids.contains(record.id) && record.id != newID {
            record.status = .merged
        }

        try modelContext.save()
    }

    /// 若目前資料表為空，將提供的 sample data 寫入；否則 no-op。
    ///
    /// 這個 helper 讓 App 第一次啟動時看到 demo 資料，後續編輯都會持久化。
    /// - Parameter samples: 要 seed 的訂單；通常傳入 ``LedgerOrder/sampleOrders``。
    /// - Returns: 是否實際執行了 seed。
    @discardableResult
    func seedIfEmpty(with samples: [LedgerOrder]) throws -> Bool {
        var descriptor = FetchDescriptor<OrderRecord>()
        descriptor.fetchLimit = 1

        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            return false
        }

        for order in samples {
            modelContext.insert(OrderRecord(order: order))
        }

        try modelContext.save()
        return true
    }
}
