//
//  CampaignServiceTests+Rename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignServiceTests {

    /// 訂單的開團名稱清單若包含重複的舊名稱，改名時替換每個相符項目
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_陣列含重複舊名稱_替換每個相符項目() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTests.makeOrder(
            id: "ORDER-CAMPAIGN-RENAME",
            campaignNames: ["秋團", "其他", "秋團"]
        )
        try await OrderServiceTests.seed([order], database: database)
        var renamedCampaign = campaign
        renamedCampaign.name = "秋季團"

        // When
        try await service.renameCampaign(renamedCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "秋季團")
        let storedOrder = try #require(
            try await OrderServiceTests.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋季團", "其他", "秋季團"])
    }

    /// 改名目標名稱去除前後空白後為空時，開團屬性更新但訂單保留舊名稱
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_目標名稱為空白_開團更新但訂單保留舊名稱() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTests.makeOrder(id: "ORDER-BLANK-TARGET", campaignNames: ["秋團"])
        try await OrderServiceTests.seed([order], database: database)
        var blankCampaign = campaign
        blankCampaign.name = "   \n\t "

        // When
        try await service.renameCampaign(blankCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "   \n\t ")
        let storedOrder = try #require(
            try await OrderServiceTests.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋團"])
    }

    /// 改名目標名稱與原名稱相同時，開團屬性更新但訂單保留舊名稱
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_目標名稱未變_開團更新但訂單保留舊名稱() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await service.saveCampaign(campaign)
        let order = OrderServiceTests.makeOrder(id: "ORDER-SAME-TARGET", campaignNames: ["秋團"])
        try await OrderServiceTests.seed([order], database: database)
        var updatedCampaign = campaign
        updatedCampaign.status = .closed

        // When
        try await service.renameCampaign(updatedCampaign, "秋團")

        // Then
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "秋團")
        #expect(storedCampaigns.first?.status == .closed)
        let storedOrder = try #require(
            try await OrderServiceTests.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋團"])
    }

    /// 改名開團更新訂單歸屬時，訂單持有的照片資料完全保持不變
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_改寫開團名稱_訂單照片保持不變() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let campaign = Campaign.fixture(
            id: "C1",
            name: "秋團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        try await service.saveCampaign(campaign)
        let photoData = [Data([0x01, 0x02, 0x03]), Data([0xAA, 0xBB])]
        let order = OrderServiceTests.makeOrder(
            id: "ORDER-PHOTO-PRESERVED",
            photos: photoData,
            campaignNames: ["秋團"]
        )
        try await OrderServiceTests.seed([order], database: database)
        var renamedCampaign = campaign
        renamedCampaign.name = "秋季團"

        // When
        try await service.renameCampaign(renamedCampaign, "秋團")

        // Then
        let storedOrder = try #require(
            try await OrderServiceTests.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["秋季團"])
        #expect(storedOrder.photos == photoData)
    }

    /// 改名成功時在單一交易內同時更新開團與訂單，資料庫寫入呼叫恰好一次
    ///
    /// - Throws: 寫入或查詢失敗時丟出 `PersistenceError.saveFailed(underlying:)` 或
    ///   `PersistenceError.fetchFailed(underlying:)`；未讀回訂單時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_改名成功_一次交易同時更新開團與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200)
        )
        let order = OrderServiceTests.makeOrder(
            id: "ORDER-SINGLE-TRANSACTION",
            campaignNames: ["四月團", "其他團"]
        )
        try await OrderServiceTests.seed([order], database: database)
        let initialService = Self.makeService(database: database)
        try await initialService.saveCampaign(campaign)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .passthrough
        let service = Self.makeService(database: mock)
        var renamedCampaign = campaign
        renamedCampaign.name = "四月團 (補)"

        // When
        try await service.renameCampaign(renamedCampaign, "四月團")

        // Then
        #expect(mock.writeCallCount == 1)
        let storedCampaigns = try await service.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "四月團 (補)")
        let storedOrder = try #require(
            try await OrderServiceTests.fetchOrder(id: order.id, from: database)
        )
        #expect(storedOrder.campaignNames == ["四月團 (補)", "其他團"])
    }

    /// 改名在儲存失敗時同成同敗，開團本體與所有訂單皆維持原名稱 (規格範例「rename with a failing save」)
    ///
    /// - Throws: fixture 建立失敗時丟出檔案或 `SwiftData` 錯誤；原有資料寫入失敗時丟出
    ///   `PersistenceError.saveFailed(underlying:)`；
    ///   `renameCampaign` 未丟出預期的 `.saveFailed(underlying:)` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func renameCampaign_儲存失敗_開團與訂單皆維持舊名稱() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let campaignService = Self.makeService(database: database)
        let originalCampaign = Campaign.fixture(
            id: "C1",
            name: "三月日本團",
            openDate: Date(timeIntervalSince1970: 1_775_779_200),
            status: .ongoing
        )
        try await campaignService.saveCampaign(originalCampaign)
        let orders = [
            OrderServiceTests.makeOrder(id: "A", campaignNames: ["三月日本團"]),
            OrderServiceTests.makeOrder(id: "B", campaignNames: ["三月日本團"]),
        ]
        try await OrderServiceTests.seed(orders, database: database)
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = Self.makeService(database: mock)
        var renamedCampaign = originalCampaign
        renamedCampaign.name = "三月日本團 (補)"
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            try await failingService.renameCampaign(renamedCampaign, "三月日本團")
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        switch error {
        case .saveFailed:
            break

        case .fetchFailed, .containerCreationFailed:
            Issue.record("預期丟出 saveFailed，但收到 \(error)")
        }
        let storedCampaigns = try await campaignService.fetchCampaigns()
        #expect(storedCampaigns.first?.name == "三月日本團")
        for id in ["A", "B"] {
            let storedOrder = try #require(
                try await OrderServiceTests.fetchOrder(id: id, from: database)
            )
            #expect(storedOrder.campaignNames == ["三月日本團"])
        }
    }
}
