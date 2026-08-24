//
//  CampaignRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 開團 (Campaign) 主檔的依賴介面
struct CampaignRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前所有開團 (依開團日期由新到舊排序)
    /// - Returns: 依日期由新到舊排序的開團
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchCampaigns: @Sendable () async throws(PersistenceError) -> [Campaign]
    
    /// 寫入或更新單一開團 (依 id upsert)
    /// - Parameter campaign: 要寫入或更新的開團
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var saveCampaign: @Sendable (_ campaign: Campaign) async throws(PersistenceError) -> Void
    
    /// 刪除開團及其訂單歸屬與提醒連結
    /// - Parameters:
    ///   - id: 開團編號
    ///   - name: 開團名稱，用於同一交易內剝除訂單歸屬
    /// - Returns: 被刪除的提醒連結事件識別碼；不存在提醒連結時為 `nil`
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removeCampaign: @Sendable (
        _ id: String,
        _ name: String
    ) async throws(PersistenceError) -> String?
}

// MARK: - Internal Method

extension CampaignRepository {
    
    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``CampaignRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> CampaignRepository {
        CampaignRepository(
            fetchCampaigns: { () async throws(PersistenceError) -> [Campaign] in
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            saveCampaign: { (campaign: Campaign) async throws(PersistenceError) in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(campaign)
            },
            removeCampaign: {
                (id: String, name: String) async throws(PersistenceError) -> String? in
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.delete(id: id, name: name)
            }
        )
    }
}

// MARK: - Private Method

private extension CampaignRepository {
    
    /// 建立 CampaignPersistence
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``CampaignPersistence`` 實例
    static func makePersistence(container: ModelContainer) async -> CampaignPersistence {
        await MainActor.run {
            CampaignPersistence(modelContainer: container)
        }
    }
}

// MARK: - Dependency Values

extension CampaignRepository: DependencyKey {
    
    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: CampaignRepository = CampaignRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫
    nonisolated static let previewValue: CampaignRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return CampaignRepository.live(container: container)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CampaignRepository(
        fetchCampaigns: { [] },
        saveCampaign: { _ in },
        removeCampaign: { _, _ in nil }
    )
}
