//
//  CampaignReminderService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension CampaignReminderService: DependencyKey {

    /// 正式 App 使用注入的資料庫讀寫開團提醒連結；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchLinks: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchLinks(in: context)
                }
            },
            saveLink: { campaignID, link throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveLink(campaignID: campaignID, link: link, in: context)
                }
            },
            removeLink: { campaignID throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeLink(campaignID: campaignID, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchLinks: unimplemented("CampaignReminderService.fetchLinks", placeholder: [:]),
            saveLink: unimplemented("CampaignReminderService.saveLink"),
            removeLink: unimplemented("CampaignReminderService.removeLink")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.campaignReminderService)` 取得的 Campaign Reminder Service
    var campaignReminderService: CampaignReminderService {
        get { self[CampaignReminderService.self] }
        set { self[CampaignReminderService.self] = newValue }
    }
}
