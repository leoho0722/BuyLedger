//
//  CampaignServiceTests+Delete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CampaignServiceTests {

    /// 刪除開團時一併移除訂單名稱與提醒連結並回傳事件識別值
    ///
    /// - Throws: 開團查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   開團儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   建立訂單時編號已存在丟出 `OrderPersistenceError.identifierCollision(id:)`；
    ///   建立訂單查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   建立訂單儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    @Test
    func removeCampaign_有訂單名稱與提醒連結_一併移除並回傳事件識別值() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let campaignService = Self.makeService(database: database)
        let orderService = OrderServiceTests.makeService(database: database)
        let reminderService = CampaignReminderServiceTests.makeService(database: database)
        try await campaignService.saveCampaign(Self.makeCampaign(id: "C1", name: "四月團"))
        try await orderService.createOrder(
            LedgerOrder.fixture(id: "O1", campaignNames: ["四月團", "五月團"])
        )
        let reminderTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        try await reminderService.saveLink(
            "C1",
            CampaignReminderLink(eventIdentifier: "EVT-1", reminderTimestamp: reminderTimestamp)
        )

        // When
        let removedIdentifier = try await campaignService.removeCampaign("C1", "四月團")

        // Then
        #expect(removedIdentifier == "EVT-1")
        let remainingCampaigns = try await campaignService.fetchCampaigns()
        #expect(remainingCampaigns.isEmpty)
        let remainingOrders = try await orderService.fetchOrders()
        #expect(remainingOrders.map(\.id) == ["O1"])
        #expect(remainingOrders.first?.campaignNames == ["五月團"])
        let remainingLinks = try await reminderService.fetchLinks()
        #expect(remainingLinks["C1"] == nil)
    }

    /// 刪除沒有提醒連結的開團時回傳 `nil`，且開團仍會被刪除
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeCampaign_沒有提醒連結_回傳空值() async throws {
        // Given
        let service = Self.makeService(database: BuyLedgerDatabaseTests.makeInMemoryDatabase())
        try await service.saveCampaign(Self.makeCampaign(id: "C1", name: "無提醒團"))

        // When
        let removedIdentifier = try await service.removeCampaign("C1", "無提醒團")

        // Then
        #expect(removedIdentifier == nil)
        let campaigns = try await service.fetchCampaigns()
        #expect(campaigns.isEmpty)
    }

    /// 刪除不存在的開團時不影響訂單
    ///
    /// - Throws: 開團查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   開團儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   建立訂單時編號已存在丟出 `OrderPersistenceError.identifierCollision(id:)`；
    ///   建立訂單查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   建立訂單儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    @Test
    func removeCampaign_識別值不存在_保留訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let campaignService = Self.makeService(database: database)
        let orderService = OrderServiceTests.makeService(database: database)
        try await orderService.createOrder(LedgerOrder.fixture(id: "O1", campaignNames: ["五月團"]))

        // When
        let removedIdentifier = try await campaignService.removeCampaign("C-absent", "不存在的團")

        // Then
        #expect(removedIdentifier == nil)
        let remainingOrders = try await orderService.fetchOrders()
        #expect(remainingOrders.map(\.id) == ["O1"])
        #expect(remainingOrders.first?.campaignNames == ["五月團"], "不存在的開團刪除不應影響任何訂單")
    }
}
