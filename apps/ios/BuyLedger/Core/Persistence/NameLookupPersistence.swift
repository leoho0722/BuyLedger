//
//  NameLookupPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import SwiftData

/// SwiftData 上對只有名稱欄位主檔做 CRUD 的泛型背景 actor
@ModelActor
actor NameLookupPersistence<Record: NameLookupRecord> {}

// MARK: - Internal Method

extension NameLookupPersistence {
    
    /// 讀出全部主檔名稱，依 locale 升冪排序
    /// - Returns: 名稱陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [String] {
        let descriptor = FetchDescriptor<Record>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map(\.name)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
    
    /// 寫入指定名稱的主檔項目；若已存在不重複建立
    /// - Parameter name: 主檔名稱 (呼叫前由 caller 完成 trim)
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
    
    /// 刪除指定名稱的主檔項目；不存在時視為 no-op
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
    
    /// 將主檔項目更名；同名時合併，訂單 cascade 由 caller 處理
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱 (由 caller 完成 trim)
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
