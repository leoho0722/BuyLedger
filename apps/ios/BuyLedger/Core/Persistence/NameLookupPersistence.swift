//
//  NameLookupPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/08/01.
//

import Foundation
import SwiftData

/// 在背景 actor 中讀寫只有名稱的主檔
@ModelActor
actor NameLookupPersistence<Record: NameLookupRecordProtocol> {}

// MARK: - Internal Method

extension NameLookupPersistence {

    /// 讀出全部主檔名稱，依使用者語言排序
    /// - Returns: 名稱陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [String] {
        let descriptor = FetchDescriptor<Record>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map(\.name)
            .sorted { left, right in
                left.localizedStandardCompare(right) == .orderedAscending
            }
    }

    /// 寫入指定名稱的主檔項目；若已存在不重複建立
    /// - Parameter name: 主檔名稱 (呼叫前由呼叫端完成去除前後空白)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func upsert(name: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))

        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if existing == nil {
            modelContext.insert(Record(name: name))
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 刪除指定名稱的主檔項目；不存在時不做任何事
    /// - Parameter name: 主檔名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func delete(name: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))

        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            modelContext.delete(record)
        }

        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// 將主檔項目更名；同名時合併，關聯訂單由呼叫端處理
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱 (由呼叫端完成去除前後空白)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func rename(from oldName: String, to newName: String) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(oldName))
        let oldRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(oldDescriptor)
        }
        for record in oldRecords {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(newName))
        let existingNew = try PersistenceError.mapFetch {
            try modelContext.fetch(newDescriptor).first
        }
        if existingNew == nil {
            modelContext.insert(Record(name: newName))
        }

        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
