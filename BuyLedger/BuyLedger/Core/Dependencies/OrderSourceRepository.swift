//
//  OrderSourceRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 訂單來源主檔的依賴介面。
struct OrderSourceRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前所有訂單來源名稱 (已排序)。
    var fetchOrderSources: @Sendable () async throws -> [String]

    /// 加入新訂單來源；trim 後若空字串視為 no-op；已存在不重複建立。
    var addOrderSource: @Sendable (String) async throws -> Void

    /// 刪除指定名稱的訂單來源；不存在視為 no-op。
    var removeOrderSource: @Sendable (String) async throws -> Void

    /// 把指定訂單來源更名 (舊名 → 新名)。caller 負責把訂單表的 cascade 一併處理；本方法只更新主檔。
    var renameOrderSource: @Sendable (String, String) async throws -> Void
}

extension OrderSourceRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository。
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container。
    /// - Returns: 對應的 ``OrderSourceRepository`` 實例。
    nonisolated static func live(container: ModelContainer) -> OrderSourceRepository {
        OrderSourceRepository(
            fetchOrderSources: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            addOrderSource: { rawName in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(name: trimmed)
            },
            removeOrderSource: { name in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(name: name)
            },
            renameOrderSource: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.rename(from: oldName, to: trimmedNew)
            }
        )
    }

    /// 在 main actor 上實例化 ``OrderSourcePersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)。
    /// - Parameter container: 共用的 ``ModelContainer``。
    /// - Returns: 對應 container 的 ``OrderSourcePersistence`` 實例。
    private static func makePersistence(container: ModelContainer) async -> OrderSourcePersistence {
        await MainActor.run {
            OrderSourcePersistence(modelContainer: container)
        }
    }
}

extension OrderSourceRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用共用 SwiftData container。
    nonisolated static let liveValue: OrderSourceRepository = OrderSourceRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container。
    nonisolated static let previewValue: OrderSourceRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return OrderSourceRepository.live(container: container)
    }()

    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫。
    nonisolated static let testValue = OrderSourceRepository(
        fetchOrderSources: { [] },
        addOrderSource: { _ in },
        removeOrderSource: { _ in },
        renameOrderSource: { _, _ in }
    )
}
