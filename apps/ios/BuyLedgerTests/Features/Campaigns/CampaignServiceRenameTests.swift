//
//  CampaignServiceRenameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignService` 的單元測試，涵蓋重新命名開團時對訂單開團名稱的連動
struct CampaignServiceRenameTests {

    /// 驗證訂單的開團名稱清單含有重複的舊名稱時，改名會替換每個相符的項目，其他名稱保留
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_陣列含重複舊名稱_替換每個相符項目() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-CAMPAIGN-RENAME",
            campaignNames: ["秋團", "其他", "秋團"]
        )
        try await OrderServiceTestSupport.seed([order], database: database)
        var renamedCampaign = campaign
        renamedCampaign.name = "秋季團"

        // When
        try await service.renameCampaign(renamedCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "秋季團")
        let storedOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋季團", "其他", "秋季團"])
    }

    /// 驗證改名目標只有空白時，開團名稱照原樣寫入，訂單的開團名稱保留舊名稱不改
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_目標名稱為空白_開團更新但訂單保留舊名稱() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-BLANK-TARGET",
            campaignNames: ["秋團"]
        )
        try await OrderServiceTestSupport.seed([order], database: database)
        var blankCampaign = campaign
        blankCampaign.name = "   \n\t "

        // When
        try await service.renameCampaign(blankCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "   \n\t ")
        let storedOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋團"])
    }

    /// 驗證改名目標與原名稱相同時，開團的狀態仍會更新，訂單的開團名稱保持不變
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_目標名稱未變_開團更新但訂單保留舊名稱() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-SAME-TARGET",
            campaignNames: ["秋團"]
        )
        try await OrderServiceTestSupport.seed([order], database: database)
        var updatedCampaign = campaign
        updatedCampaign.status = .closed

        // When
        try await service.renameCampaign(updatedCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "秋團")
        #expect(storedCampaigns.first?.status == .closed)
        let storedOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋團"])
    }

    /// 驗證改名更新訂單的開團歸屬時，訂單的照片資料完全保持不變
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_改寫開團名稱_訂單照片保持不變() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let photoData = [Data([0x01, 0x02, 0x03]), Data([0xAA, 0xBB])]
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-PHOTO-PRESERVED",
            photos: photoData,
            campaignNames: ["秋團"]
        )
        try await OrderServiceTestSupport.seed([order], database: database)
        var renamedCampaign = campaign
        renamedCampaign.name = "秋季團"

        // When
        try await service.renameCampaign(renamedCampaign, "秋團")

        // Then
        let storedOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋季團"])
        #expect(storedOrder.photos == photoData)
    }

    /// 驗證改名成功時，開團與訂單在單一交易內同時更新，資料庫寫入只呼叫一次
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_改名成功_一次交易同時更新開團與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        let order = OrderServiceTestSupport.makeOrder(
            id: "ORDER-SINGLE-TRANSACTION",
            campaignNames: ["四月團", "其他團"]
        )
        try await OrderServiceTestSupport.seed([order], database: database)
        let initialService = CampaignServiceTestSupport.makeService(database: database)
        try await initialService.saveCampaign(campaign)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .passthrough
        let service = CampaignServiceTestSupport.makeService(database: mock)
        var renamedCampaign = campaign
        renamedCampaign.name = "四月團 (補)"

        // When
        try await service.renameCampaign(renamedCampaign, "四月團")

        // Then
        #expect(mock.writeCallCount == 1)
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "四月團 (補)")
        let storedOrder = try #require(
            try await OrderServiceTestSupport.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["四月團 (補)", "其他團"])
    }

    /// 驗證改名遇到儲存失敗時，開團與所有訂單皆維持舊名稱，兩者同成同敗 (規格範例「rename with a failing save」)
    ///
    /// - Throws: fixture 建立失敗時丟出檔案或 SwiftData 錯誤；原有資料寫入失敗時丟出
    ///   `PersistenceError.saveFailed(underlying:)`；
    ///   `renameCampaign` 未丟出預期的 `.saveFailed(underlying:)` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_儲存失敗_開團與訂單皆維持舊名稱() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let campaignService = CampaignServiceTestSupport.makeService(database: database)
        let originalCampaign = Campaign.fixture(
            id: "C1",
            name: "三月日本團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await campaignService.saveCampaign(originalCampaign)
        let orders = [
            OrderServiceTestSupport.makeOrder(id: "A", campaignNames: ["三月日本團"]),
            OrderServiceTestSupport.makeOrder(id: "B", campaignNames: ["三月日本團"]),
        ]
        try await OrderServiceTestSupport.seed(orders, database: database)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = CampaignServiceTestSupport.makeService(database: mock)
        var renamedCampaign = originalCampaign
        renamedCampaign.name = "三月日本團 (補)"
        var actualError: PersistenceError?

        // When
        do {
            try await failingService.renameCampaign(renamedCampaign, "三月日本團")
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        #expect(isSaveFailure, "預期丟出 saveFailed，但收到 \(error)")
        let storedCampaigns = try await campaignService.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "三月日本團")
        for id in ["A", "B"] {
            let storedOrder = try #require(
                try await OrderServiceTestSupport.fetchOrder(id: id, from: database)
            )
            #expect(storedOrder.campaignNames == ["三月日本團"])
        }
    }
}
