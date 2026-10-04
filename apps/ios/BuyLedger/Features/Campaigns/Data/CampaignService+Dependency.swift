//
//  CampaignService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension CampaignService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行開團操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
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
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchCampaigns: unimplemented("CampaignService.fetchCampaigns", placeholder: []),
            saveCampaign: unimplemented("CampaignService.saveCampaign"),
            removeCampaign: unimplemented("CampaignService.removeCampaign", placeholder: nil)
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
