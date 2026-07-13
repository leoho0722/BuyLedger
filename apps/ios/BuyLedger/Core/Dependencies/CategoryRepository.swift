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
    var fetchCategories: @Sendable () async throws -> [String]

    /// 加入新類別；trim 後若空字串視為 no-op；已存在不重複建立
    /// - Parameter rawName: 要加入的名稱 (未 trim)
    var addCategory: @Sendable (_ rawName: String) async throws -> Void

    /// 刪除指定名稱的類別；不存在視為 no-op
    /// - Parameter name: 要刪除的名稱
    var removeCategory: @Sendable (_ name: String) async throws -> Void

    /// 把指定類別更名 (舊名 → 新名)。caller 負責把訂單表的 cascade 一併處理；本方法只更新主檔
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    var renameCategory: @Sendable (_ oldName: String, _ newName: String) async throws -> Void
}

// MARK: - Internal Method

extension CategoryRepository {

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``CategoryRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> CategoryRepository {
        CategoryRepository(
            fetchCategories: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            addCategory: { rawName in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(name: trimmed)
            },
            removeCategory: { name in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(name: name)
            },
            renameCategory: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.rename(from: oldName, to: trimmedNew)
            }
        )
    }
}

// MARK: - Private Method

private extension CategoryRepository {

    /// 在 main actor 上實例化 ``CategoryPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``CategoryPersistence`` 實例
    static func makePersistence(container: ModelContainer) async -> CategoryPersistence {
        await MainActor.run {
            CategoryPersistence(modelContainer: container)
        }
    }
}

// MARK: - Dependency Values

extension CategoryRepository: DependencyKey {

    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: CategoryRepository = CategoryRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container
    nonisolated static let previewValue: CategoryRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
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
