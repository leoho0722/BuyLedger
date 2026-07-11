//
//  CampaignReminderRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/11.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 開團訂購提醒的連結資料：行事曆事件識別碼與使用者選定的提醒時間戳
struct CampaignReminderLink: Equatable, Sendable {

    // MARK: - Data Properties

    /// 對應的系統行事曆事件識別碼
    let eventIdentifier: String

    /// 提醒時間戳 (使用者選定的日期＋提示時間)
    let reminderTimestamp: Date
}

/// 「開團訂購提醒連結」(campaignID → ``CampaignReminderLink``) 的依賴介面
///
/// 連結存於 iOS 端專屬的 ``CampaignReminderRecord`` 表，與跨平台 ``Campaign`` 型別解耦。儲存以 campaignID upsert，涵蓋新增與更新
struct CampaignReminderRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取全部連結，回傳 campaignID → ``CampaignReminderLink`` 字典
    var fetchLinks: @Sendable () async throws -> [String: CampaignReminderLink]

    /// 寫入或更新單一連結 (依 campaignID upsert)
    var saveLink: @Sendable (_ campaignID: String, _ eventIdentifier: String, _ reminderTimestamp: Date) async throws -> Void

    /// 刪除指定 campaignID 的連結；不存在視為 no-op
    var removeLink: @Sendable (_ campaignID: String) async throws -> Void
}

extension CampaignReminderRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``CampaignReminderRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> CampaignReminderRepository {
        CampaignReminderRepository(
            fetchLinks: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            saveLink: { campaignID, eventIdentifier, reminderTimestamp in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(campaignID: campaignID, eventIdentifier: eventIdentifier, reminderTimestamp: reminderTimestamp)
            },
            removeLink: { campaignID in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(campaignID: campaignID)
            }
        )
    }

    /// 在 main actor 上實例化 ``CampaignReminderPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``CampaignReminderPersistence`` 實例
    private static func makePersistence(container: ModelContainer) async -> CampaignReminderPersistence {
        await MainActor.run {
            CampaignReminderPersistence(modelContainer: container)
        }
    }
}

extension CampaignReminderRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: CampaignReminderRepository = CampaignReminderRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container
    nonisolated static let previewValue: CampaignReminderRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return CampaignReminderRepository.live(container: container)
    }()

    /// 測試預設回傳空連結；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CampaignReminderRepository(
        fetchLinks: { [:] },
        saveLink: { _, _, _ in },
        removeLink: { _ in }
    )
}
