//
//  OrderSourceRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 訂單來源主檔的依賴介面
struct OrderSourceRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前所有訂單來源名稱 (已排序)
    /// - Returns: 已排序的訂單來源名稱
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchOrderSources: @Sendable () async throws(PersistenceError) -> [String]
    
    /// 加入新訂單來源；trim 後若空字串視為 no-op；已存在不重複建立
    /// - Parameter rawName: 要加入的名稱 (未 trim)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var addOrderSource: @Sendable (_ rawName: String) async throws(PersistenceError) -> Void
    
    /// 刪除指定名稱的訂單來源；不存在視為 no-op
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removeOrderSource: @Sendable (_ name: String) async throws(PersistenceError) -> Void
    
    /// 更名訂單來源；只更新主檔
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderSource: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension OrderSourceRepository {
    
    /// 以指定的 ModelContainer 建立資料來源；操作委派給 NameLookupOperations
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``OrderSourceRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> OrderSourceRepository {
        OrderSourceRepository(
            fetchOrderSources: { () async throws(PersistenceError) -> [String] in
                try await NameLookupOperations<OrderSourceRecord>.fetchAll(container: container)
            },
            addOrderSource: { (rawName: String) async throws(PersistenceError) in
                try await NameLookupOperations<OrderSourceRecord>.add(
                    rawName: rawName, container: container)
            },
            removeOrderSource: { (name: String) async throws(PersistenceError) in
                try await NameLookupOperations<OrderSourceRecord>.remove(
                    name: name, container: container)
            },
            renameOrderSource: {
                (oldName: String, newName: String) async throws(PersistenceError) in
                try await NameLookupOperations<OrderSourceRecord>.rename(
                    oldName: oldName, newName: newName, container: container)
            }
        )
    }
}

// MARK: - Dependency Values

extension OrderSourceRepository: DependencyKey {
    
    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: OrderSourceRepository = OrderSourceRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫
    nonisolated static let previewValue: OrderSourceRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return OrderSourceRepository.live(container: container)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = OrderSourceRepository(
        fetchOrderSources: { [] },
        addOrderSource: { _ in },
        removeOrderSource: { _ in },
        renameOrderSource: { _, _ in }
    )
}
