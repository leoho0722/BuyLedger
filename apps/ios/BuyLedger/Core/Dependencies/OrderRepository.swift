//
//  OrderRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 讀取與寫入訂單資料的依賴介面
///
/// 背後接 SwiftData 純本機儲存；CloudKit 同步策略透過 ``PersistenceContainer/CloudKitOption`` 設定，目前以 ``PersistenceContainer/CloudKitOption/disabled`` 執行，待 Apple Developer 帳號完成 provision 後才會打開
struct OrderRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前可顯示的訂單
    ///
    /// runtime 不再自動以 ``LedgerOrder/sampleOrders`` seed 空資料庫——首次啟動會看到真正的空狀態。仍想用 sample 資料填充時請使用 `previewValue` (在 SwiftUI Preview 與測試 fixture 中)
    var fetchOrders: @Sendable () async throws -> [LedgerOrder]

    /// 將單筆訂單寫入或更新 (依 id upsert)
    var saveOrder: @Sendable (LedgerOrder) async throws -> Void

    /// 將多筆訂單以單一持久化操作 (單次 save) 寫入或更新 (依 id upsert)，供批次更改狀態原子落盤
    var saveOrders: @Sendable ([LedgerOrder]) async throws -> Void

    /// 刪除指定編號的訂單
    var removeOrder: @Sendable (LedgerOrder.ID) async throws -> Void

    /// 以單一持久化操作完成合併：寫入合併後新訂單，並把來源訂單狀態改為「已合併」
    var mergeOrders: @Sendable (LedgerOrder, [LedgerOrder.ID]) async throws -> Void

    /// 把所有訂單的 ``LedgerOrder/orderSource`` 由 `oldName` 改成 `newName` (cascade rename)
    var renameOrderSource: @Sendable (String, String) async throws -> Void

    /// 把所有訂單的 ``LedgerOrder/category`` 由 `oldName` 改成 `newName` (cascade rename)
    var renameOrderCategory: @Sendable (String, String) async throws -> Void

    /// 把所有訂單的 ``LedgerOrder/paymentMethod`` 由 `oldName` 改成 `newName` (cascade rename)
    var renameOrderPaymentMethod: @Sendable (String, String) async throws -> Void

    /// 把所有訂單的 ``LedgerOrder/verificationStatus`` 由 `oldName` 改成 `newName` (cascade rename)
    var renameOrderVerificationStatus: @Sendable (String, String) async throws -> Void

    /// 把所有訂單的 ``LedgerOrder/campaignNames`` 由 `oldName` 改成 `newName` (開團 cascade rename)
    var renameOrderCampaign: @Sendable (String, String) async throws -> Void
}

extension OrderRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    ///
    /// ``OrderPersistence`` (@ModelActor) 的 init 預設帶有 main-actor 隔離資訊，因此 actor 實例必須在 closure 執行時 (async context) 才實例化，避免在 `nonisolated static let` 初始化階段觸發 actor isolation 衝突
    /// - Parameters:
    ///   - container: 用於建立背景 actor 的 SwiftData container
    ///   - seedSampleOrdersIfEmpty: 當資料表為空時是否自動 seed ``LedgerOrder/sampleOrders``；runtime 預設為 `false`，僅 SwiftUI Preview 應傳 `true` 以便畫面有資料可看
    /// - Returns: 對應的 ``OrderRepository`` 實例
    nonisolated static func live(
        container: ModelContainer,
        seedSampleOrdersIfEmpty: Bool = false
    ) -> OrderRepository {
        OrderRepository(
            fetchOrders: {
                let persistence = await Self.makePersistence(container: container)
                let stored = try await persistence.fetchAll()
                if seedSampleOrdersIfEmpty, stored.isEmpty {
                    _ = try await persistence.seedIfEmpty(with: LedgerOrder.sampleOrders)
                    return try await persistence.fetchAll()
                }
                return stored
            },
            saveOrder: { order in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(order)
            },
            saveOrders: { orders in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsertAll(orders)
            },
            removeOrder: { id in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(id: id)
            },
            mergeOrders: { newOrder, consumedIDs in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.mergeOrders(newOrder: newOrder, consumedIDs: consumedIDs)
            },
            renameOrderSource: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.renameOrderSource(from: oldName, to: trimmedNew)
            },
            renameOrderCategory: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.renameCategory(from: oldName, to: trimmedNew)
            },
            renameOrderPaymentMethod: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.renamePaymentMethod(from: oldName, to: trimmedNew)
            },
            renameOrderVerificationStatus: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.renameVerificationStatus(from: oldName, to: trimmedNew)
            },
            renameOrderCampaign: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.renameCampaign(from: oldName, to: trimmedNew)
            }
        )
    }

    /// 在 main actor 上實例化 ``OrderPersistence``
    ///
    /// `@ModelActor` 自動產生的 init 帶有 main-actor 隔離 (因內部需建立 ``ModelContext``)，所以無法直接在 nonisolated 的 closure 中呼叫；統一在這裡用 ``MainActor/run(resultType:body:)`` 跳上 main 拿到 actor 後再回到原 task
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``OrderPersistence`` 實例
    private static func makePersistence(container: ModelContainer) async -> OrderPersistence {
        await MainActor.run {
            OrderPersistence(modelContainer: container)
        }
    }
}

extension OrderRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用本機 SwiftData 儲存 (共用 ``PersistenceContainer/shared``)
    nonisolated static let liveValue: OrderRepository = OrderRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory SwiftData，避免污染本機資料庫；自動 seed sample 資料以便畫面有內容可看
    nonisolated static let previewValue: OrderRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.makeForApp()

        return OrderRepository.live(container: container, seedSampleOrdersIfEmpty: true)
    }()

    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = OrderRepository(
        fetchOrders: { [] },
        saveOrder: { _ in },
        saveOrders: { _ in },
        removeOrder: { _ in },
        mergeOrders: { _, _ in },
        renameOrderSource: { _, _ in },
        renameOrderCategory: { _, _ in },
        renameOrderPaymentMethod: { _, _ in },
        renameOrderVerificationStatus: { _, _ in },
        renameOrderCampaign: { _, _ in }
    )
}
