//
//  CampaignServiceTests+DeleteFailure.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CampaignServiceTests {

    /// 刪除交易儲存失敗時保留開團、訂單歸屬與提醒連結
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；查詢失敗時丟出
    ///   `PersistenceError.fetchFailed(underlying:)`；儲存失敗時丟出
    ///   `PersistenceError.saveFailed(underlying:)`；`removeCampaign` 沒有丟出錯誤時由 `#require`
    ///   丟出測試斷言錯誤
    @Test
    func removeCampaign_交易儲存失敗_保留開團訂單與提醒() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture(
            orders: [LedgerOrder.fixture(id: "O1", campaignNames: ["四月團"])]
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let campaignService = Self.makeService(database: database)
        let orderService = OrderServiceTests.makeService(database: database)
        let reminderService = CampaignReminderServiceTests.makeService(database: database)
        try await campaignService.saveCampaign(Self.makeCampaign(id: "C1", name: "四月團"))
        let reminderTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        try await reminderService.saveLink(
            "C1",
            CampaignReminderLink(eventIdentifier: "EVT-1", reminderTimestamp: reminderTimestamp)
        )
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = Self.makeService(database: mock)
        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            _ = try await failingService.removeCampaign("C1", "四月團")
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
        #expect(isSaveFailure)
        let remainingCampaigns = try await campaignService.fetchCampaigns()
        #expect(remainingCampaigns.map(\.id) == ["C1"], "save 失敗時開團仍應存在")
        let remainingOrders = try await orderService.fetchOrders()
        #expect(remainingOrders.map(\.id) == ["O1"])
        #expect(remainingOrders.first?.campaignNames == ["四月團"], "save 失敗時訂單的開團名稱不應被剝除")
        let remainingLinks = try await reminderService.fetchLinks()
        #expect(
            remainingLinks["C1"] == CampaignReminderLink(
                eventIdentifier: "EVT-1",
                reminderTimestamp: reminderTimestamp
            )
        )
    }
}
