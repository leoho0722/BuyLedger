//
//  NameLookupOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import SwiftData

/// 共用名稱主檔操作，統一處理去空白與空值
enum NameLookupOperations<Record: NameLookupRecord> {}

// MARK: - Internal Method

extension NameLookupOperations {
    
    /// 讀取目前所有主檔名稱 (已排序)
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 名稱陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    static func fetchAll(container: ModelContainer) async throws(PersistenceError) -> [String] {
        try await persistence(container: container).fetchAll()
    }
    
    /// 加入新主檔項目；trim 後若空字串視為 no-op；已存在不重複建立
    /// - Parameters:
    ///   - rawName: 要加入的名稱 (未 trim)
    ///   - container: 用於建立背景 actor 的 SwiftData container
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    static func add(rawName: String, container: ModelContainer) async throws(PersistenceError) {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        try await persistence(container: container).upsert(name: trimmed)
    }
    
    /// 刪除指定名稱的主檔項目；不存在視為 no-op
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - container: 用於建立背景 actor 的 SwiftData container
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    static func remove(name: String, container: ModelContainer) async throws(PersistenceError) {
        try await persistence(container: container).delete(name: name)
    }
    
    /// 更名主檔項目；新名為空或相同時不處理
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱 (未 trim)
    ///   - container: 用於建立背景 actor 的 SwiftData container
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    static func rename(
        oldName: String,
        newName: String,
        container: ModelContainer
    ) async throws(PersistenceError) {
        let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNew.isEmpty, trimmedNew != oldName else {
            return
        }
        try await persistence(container: container).rename(from: oldName, to: trimmedNew)
    }
}

// MARK: - Private Method

private extension NameLookupOperations {
    
    /// 建立 NameLookupPersistence
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``NameLookupPersistence`` 實例
    static func persistence(container: ModelContainer) async -> NameLookupPersistence<Record> {
        await MainActor.run {
            NameLookupPersistence<Record>(modelContainer: container)
        }
    }
}
