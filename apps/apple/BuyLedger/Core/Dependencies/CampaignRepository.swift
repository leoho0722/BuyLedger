//
//  CampaignRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 開團 (Campaign) 主檔的依賴介面。
///
/// 開團是有狀態的獨立實體，故介面回傳完整 ``Campaign`` (含狀態與日期)，而非僅名稱。儲存以 ``Campaign/id`` upsert，同時涵蓋新增、改名與狀態變更；訂單端的 cascade rename 由 ``OrderRepository/renameOrderCampaign`` 另外處理。
struct CampaignRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前所有開團 (依開團日期由新到舊排序)。
    var fetchCampaigns: @Sendable () async throws -> [Campaign]

    /// 寫入或更新單一開團 (依 id upsert)。
    var saveCampaign: @Sendable (Campaign) async throws -> Void

    /// 刪除指定 id 的開團；不存在視為 no-op。
    var removeCampaign: @Sendable (String) async throws -> Void
}

extension CampaignRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository。
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container。
    /// - Returns: 對應的 ``CampaignRepository`` 實例。
    nonisolated static func live(container: ModelContainer) -> CampaignRepository {
        CampaignRepository(
            fetchCampaigns: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            saveCampaign: { campaign in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(campaign)
            },
            removeCampaign: { id in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(id: id)
            }
        )
    }

    /// 在 main actor 上實例化 ``CampaignPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)。
    /// - Parameter container: 共用的 ``ModelContainer``。
    /// - Returns: 對應 container 的 ``CampaignPersistence`` 實例。
    private static func makePersistence(container: ModelContainer) async -> CampaignPersistence {
        await MainActor.run {
            CampaignPersistence(modelContainer: container)
        }
    }
}

extension CampaignRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用共用 SwiftData container。
    nonisolated static let liveValue: CampaignRepository = CampaignRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container。
    nonisolated static let previewValue: CampaignRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return CampaignRepository.live(container: container)
    }()

    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫。
    nonisolated static let testValue = CampaignRepository(
        fetchCampaigns: { [] },
        saveCampaign: { _ in },
        removeCampaign: { _ in }
    )
}
