//
//  CampaignService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension CampaignService: DependencyKey {

    /// 以注入的資料庫執行開團操作，供正式 App 使用
    ///
    /// - Note: 必須是 computed property，測試才能用 `withDependencies` 換掉資料庫相依
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchCampaigns: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchCampaigns(in: context)
                }
            },
            saveCampaign: { campaign throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveCampaign(campaign, in: context)
                }
            },
            removeCampaign: { id, name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeCampaign(id: id, name: name, in: context)
                }
            },
            renameCampaign: { campaign, previousName throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.renameCampaign(campaign, previousName: previousName, in: context)
                }
            },
            fetchReminderLinks: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchReminderLinks(in: context)
                }
            },
            saveReminderLink: { campaignID, link throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveReminderLink(campaignID: campaignID, link: link, in: context)
                }
            },
            removeReminderLink: { campaignID throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeReminderLink(campaignID: campaignID, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchCampaigns: unimplemented("CampaignService.fetchCampaigns", placeholder: []),
            saveCampaign: unimplemented("CampaignService.saveCampaign"),
            removeCampaign: unimplemented("CampaignService.removeCampaign", placeholder: nil),
            renameCampaign: unimplemented("CampaignService.renameCampaign"),
            fetchReminderLinks: unimplemented(
                "CampaignService.fetchReminderLinks",
                placeholder: [:]
            ),
            saveReminderLink: unimplemented("CampaignService.saveReminderLink"),
            removeReminderLink: unimplemented("CampaignService.removeReminderLink")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.campaignService)` 取得的 Campaign Service
    var campaignService: CampaignService {
        get { self[CampaignService.self] }
        set { self[CampaignService.self] = newValue }
    }
}
