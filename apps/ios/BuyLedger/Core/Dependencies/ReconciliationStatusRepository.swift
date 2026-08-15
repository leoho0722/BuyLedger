//
//  ReconciliationStatusRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 對帳狀態主檔的依賴介面
struct ReconciliationStatusRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前所有對帳狀態名稱 (已排序)
    /// - Returns: 已排序的對帳狀態名稱
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchReconciliationStatuses: @Sendable () async throws(PersistenceError) -> [String]
    
    /// 加入新對帳狀態；trim 後若空字串視為 no-op；已存在不重複建立
    /// - Parameter rawName: 要加入的名稱 (未 trim)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var addReconciliationStatus: @Sendable (_ rawName: String) async throws(PersistenceError) -> Void
    
    /// 刪除指定名稱的對帳狀態；不存在視為 no-op
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removeReconciliationStatus: @Sendable (_ name: String) async throws(PersistenceError) -> Void
    
    /// 更名對帳狀態；只更新主檔
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameReconciliationStatus: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension ReconciliationStatusRepository {
    
    /// 以指定的 ModelContainer 建立資料來源；操作委派給 NameLookupOperations
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``ReconciliationStatusRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> ReconciliationStatusRepository {
        ReconciliationStatusRepository(
            fetchReconciliationStatuses: { () async throws(PersistenceError) -> [String] in
                try await NameLookupOperations<ReconciliationStatusRecord>.fetchAll(container: container)
            },
            addReconciliationStatus: { (rawName: String) async throws(PersistenceError) in
                try await NameLookupOperations<ReconciliationStatusRecord>.add(
                    rawName: rawName,
                    container: container
                )
            },
            removeReconciliationStatus: { (name: String) async throws(PersistenceError) in
                try await NameLookupOperations<ReconciliationStatusRecord>.remove(
                    name: name,
                    container: container
                )
            },
            renameReconciliationStatus: { (oldName: String, newName: String) async throws(PersistenceError) in
                try await NameLookupOperations<ReconciliationStatusRecord>.rename(
                    oldName: oldName,
                    newName: newName,
                    container: container
                )
            }
        )
    }
}

// MARK: - Dependency Values

extension ReconciliationStatusRepository: DependencyKey {
    
    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: ReconciliationStatusRepository =
    ReconciliationStatusRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫
    nonisolated static let previewValue: ReconciliationStatusRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return ReconciliationStatusRepository.live(container: container)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = ReconciliationStatusRepository(
        fetchReconciliationStatuses: { [] },
        addReconciliationStatus: { _ in },
        removeReconciliationStatus: { _ in },
        renameReconciliationStatus: { _, _ in }
    )
}
