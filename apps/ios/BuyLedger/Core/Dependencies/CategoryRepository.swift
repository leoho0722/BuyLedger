//
//  CategoryRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 商品類別主檔的依賴介面
struct CategoryRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前所有類別名稱 (已排序)
    /// - Returns: 已排序的類別名稱
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchCategories: @Sendable () async throws(PersistenceError) -> [String]
    
    /// 加入新類別；trim 後若空字串視為 no-op；已存在不重複建立
    /// - Parameter rawName: 要加入的名稱 (未 trim)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var addCategory: @Sendable (_ rawName: String) async throws(PersistenceError) -> Void
    
    /// 刪除指定名稱的類別；不存在視為 no-op
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removeCategory: @Sendable (_ name: String) async throws(PersistenceError) -> Void
    
    /// 更名類別；只更新主檔
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameCategory: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension CategoryRepository {
    
    /// 以指定的 ModelContainer 建立資料來源；操作委派給 NameLookupOperations
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``CategoryRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> CategoryRepository {
        CategoryRepository(
            fetchCategories: { () async throws(PersistenceError) -> [String] in
                try await NameLookupOperations<CategoryRecord>.fetchAll(container: container)
            },
            addCategory: { (rawName: String) async throws(PersistenceError) in
                try await NameLookupOperations<CategoryRecord>.add(
                    rawName: rawName,
                    container: container
                )
            },
            removeCategory: { (name: String) async throws(PersistenceError) in
                try await NameLookupOperations<CategoryRecord>.remove(
                    name: name,
                    container: container
                )
            },
            renameCategory: {
                (oldName: String, newName: String) async throws(PersistenceError) in
                try await NameLookupOperations<CategoryRecord>.rename(
                    oldName: oldName,
                    newName: newName,
                    container: container
                )
            }
        )
    }
}

// MARK: - Dependency Values

extension CategoryRepository: DependencyKey {
    
    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: CategoryRepository = CategoryRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫
    nonisolated static let previewValue: CategoryRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return CategoryRepository.live(container: container)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CategoryRepository(
        fetchCategories: { [] },
        addCategory: { _ in },
        removeCategory: { _ in },
        renameCategory: { _, _ in }
    )
}
