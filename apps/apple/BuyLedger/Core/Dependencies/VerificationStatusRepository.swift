//
//  VerificationStatusRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 對帳狀態主檔的依賴介面。
struct VerificationStatusRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前所有對帳狀態名稱 (已排序)。
    var fetchVerificationStatuses: @Sendable () async throws -> [String]

    /// 加入新對帳狀態；trim 後若空字串視為 no-op；已存在不重複建立。
    var addVerificationStatus: @Sendable (String) async throws -> Void

    /// 刪除指定名稱的對帳狀態；不存在視為 no-op。
    var removeVerificationStatus: @Sendable (String) async throws -> Void

    /// 把指定對帳狀態更名 (舊名 → 新名)。caller 負責把訂單表的 cascade 一併處理；本方法只更新主檔。
    var renameVerificationStatus: @Sendable (String, String) async throws -> Void
}

extension VerificationStatusRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository。
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container。
    /// - Returns: 對應的 ``VerificationStatusRepository`` 實例。
    nonisolated static func live(container: ModelContainer) -> VerificationStatusRepository {
        VerificationStatusRepository(
            fetchVerificationStatuses: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            addVerificationStatus: { rawName in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(name: trimmed)
            },
            removeVerificationStatus: { name in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(name: name)
            },
            renameVerificationStatus: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.rename(from: oldName, to: trimmedNew)
            }
        )
    }

    /// 在 main actor 上實例化 ``VerificationStatusPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)。
    /// - Parameter container: 共用的 ``ModelContainer``。
    /// - Returns: 對應 container 的 ``VerificationStatusPersistence`` 實例。
    private static func makePersistence(container: ModelContainer) async -> VerificationStatusPersistence {
        await MainActor.run {
            VerificationStatusPersistence(modelContainer: container)
        }
    }
}

extension VerificationStatusRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用共用 SwiftData container。
    nonisolated static let liveValue: VerificationStatusRepository = VerificationStatusRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container。
    nonisolated static let previewValue: VerificationStatusRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return VerificationStatusRepository.live(container: container)
    }()

    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫。
    nonisolated static let testValue = VerificationStatusRepository(
        fetchVerificationStatuses: { [] },
        addVerificationStatus: { _ in },
        removeVerificationStatus: { _ in },
        renameVerificationStatus: { _, _ in }
    )
}
