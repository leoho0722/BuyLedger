//
//  OrderSourcePersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 上對訂單來源主檔做 CRUD 的背景 actor。
@ModelActor
actor OrderSourcePersistence {

    // MARK: - View Method

    /// 讀出全部訂單來源名稱，依 locale 升冪排序。
    /// - Returns: 訂單來源名稱陣列。
    func fetchAll() throws -> [String] {
        let descriptor = FetchDescriptor<OrderSourceRecord>()
        let records = try modelContext.fetch(descriptor)
        return records
            .map { $0.name }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 寫入指定名稱的訂單來源；若已存在不重複建立。
    /// - Parameter name: 訂單來源名稱 (呼叫前由 caller 完成 trim)。
    func upsert(name: String) throws {
        let descriptor = FetchDescriptor<OrderSourceRecord>(
            predicate: #Predicate { $0.name == name }
        )

        if try modelContext.fetch(descriptor).first == nil {
            modelContext.insert(OrderSourceRecord(name: name))
            try modelContext.save()
        }
    }

    /// 刪除指定名稱的訂單來源；不存在時視為 no-op。
    /// - Parameter name: 訂單來源名稱。
    func delete(name: String) throws {
        let descriptor = FetchDescriptor<OrderSourceRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    /// 將指定訂單來源更名；若新名稱已存在則合併 (刪除舊紀錄即可)，訂單端的 cascade 由 caller 另外處理。
    /// - Parameters:
    ///   - oldName: 原本的訂單來源名稱。
    ///   - newName: 新的訂單來源名稱 (由 caller 完成 trim)。
    func rename(from oldName: String, to newName: String) throws {
        let oldDescriptor = FetchDescriptor<OrderSourceRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        for record in try modelContext.fetch(oldDescriptor) {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<OrderSourceRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        if try modelContext.fetch(newDescriptor).first == nil {
            modelContext.insert(OrderSourceRecord(name: newName))
        }

        try modelContext.save()
    }
}
