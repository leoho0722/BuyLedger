//
//  CampaignServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團 Service 的讀取、寫入與刪除行為
struct CampaignServiceTests {

    /// 全新資料庫不預先帶入任何開團，讀取回傳空陣列
    ///
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    @Test
    func fetchCampaigns_全新資料庫_回傳空陣列() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())

        // When
        let campaigns = try await service.fetchCampaigns()

        // Then
        #expect(campaigns.isEmpty)
    }

    /// 相同識別值再次儲存時不新增第二筆，原有開團的名稱與狀態都更新為新值
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveCampaign_開團識別值相同_更新既有開團() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月韓國團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await service.saveCampaign(campaign)
        let insertedCampaigns = try await service.fetchCampaigns()
        try #require(insertedCampaigns.count == 1)
        let insertedCampaign = try #require(insertedCampaigns.first)
        try #require(insertedCampaign.name == "四月韓國團")
        try #require(insertedCampaign.status == .ongoing)
        var renamedClosed = campaign
        renamedClosed.name = "四月韓國團 (補)"
        renamedClosed.status = .closed

        // When
        try await service.saveCampaign(renamedClosed)

        // Then
        let afterUpdate = try await service.fetchCampaigns()
        #expect(afterUpdate.count == 1, "相同 id 應 upsert 更新而非新增")
        #expect(afterUpdate.first?.name == "四月韓國團 (補)")
        #expect(afterUpdate.first?.status == .closed)
    }

    /// 讀取多筆開團時依開團日期由新到舊排列，而不是依儲存先後
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func fetchCampaigns_多筆開團_依開團日期由新到舊排序() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.saveCampaign(Campaign.fixture(
            id: "old",
            name: "三月團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600)
        ))
        try await service.saveCampaign(Campaign.fixture(
            id: "new",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200)
        ))

        // When
        let campaigns = try await service.fetchCampaigns()

        // Then
        #expect(campaigns.map(\.id) == ["new", "old"])
    }

    /// 依識別值刪除開團，只移除相符的那一筆，其他開團保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeCampaign_識別值相符_刪除開團() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.saveCampaign(Campaign.fixture(
            id: "C1",
            name: "團一",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        ))
        try await service.saveCampaign(Campaign.fixture(
            id: "C2",
            name: "團二",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        ))

        // When
        _ = try await service.removeCampaign("C1", "團一")

        // Then
        let campaigns = try await service.fetchCampaigns()
        #expect(campaigns.map(\.id) == ["C2"])
    }

    /// 儲存後保留開團的結單與結算日期
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；預期結果不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveCampaign_結單與結算日期_往返後保留原日期() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        let close = Date(timeIntervalSince1970: 1_700_000_000)
        let settled = Date(timeIntervalSince1970: 1_800_000_000)
        var campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .closed
        )
        campaign.closeDate = close
        campaign.settledDate = settled

        // When
        try await service.saveCampaign(campaign)

        // Then
        let campaigns = try await service.fetchCampaigns()
        #expect(campaigns.count == 1)
        let fetched = try #require(campaigns.first)
        #expect(fetched.closeDate == close)
        #expect(fetched.settledDate == settled)
        #expect(fetched.isSettled)
    }
}

// MARK: - Internal Method

extension CampaignServiceTests {

    /// 以注入的資料庫建立正式 `CampaignService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `CampaignService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> CampaignService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CampaignService.liveValue
        }
    }
}
