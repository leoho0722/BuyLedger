//
//  CampaignServiceDeleteTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignService` 的單元測試，涵蓋刪除開團時對訂單開團名稱與提醒連結的連動
struct CampaignServiceDeleteTests {

    /// 驗證刪除開團時，訂單上的開團名稱與提醒連結一併移除，並回傳提醒的事件識別值
    ///
    /// - Throws: 開團查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   開團儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   建立訂單時編號已存在丟出 `OrderError.identifierCollision(id:)`；
    ///   建立訂單查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   建立訂單儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    @Test
    func removeCampaign_有訂單名稱與提醒連結_一併移除並回傳事件識別值() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let campaignService = CampaignServiceTestSupport.makeService(database: database)
        let orderService = OrderServiceTestSupport.makeService(database: database)
        try await campaignService.saveCampaign(
            Campaign.fixture(
                id: "C1",
                name: "四月團",
                openDate: Date(timeIntervalSince1970: 1_775_779_200)
            )
        )
        try await orderService.createOrder(
            LedgerOrder.fixture(id: "O1", campaignNames: ["四月團", "五月團"])
        )
        let reminderTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        try await campaignService.saveReminderLink(
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
        let remainingLinks = try await campaignService.fetchReminderLinks()
        #expect(remainingLinks["C1"] == nil)
    }

    /// 驗證刪除沒有提醒連結的開團時回傳 `nil`，且開團本身仍被刪除
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func removeCampaign_沒有提醒連結_回傳空值() async throws {
        // Given
        let service = CampaignServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        )
        try await service.saveCampaign(
            Campaign.fixture(
                id: "C1",
                name: "無提醒團",
                openDate: Date(timeIntervalSince1970: 1_775_779_200)
            )
        )

        // When
        let removedIdentifier = try await service.removeCampaign("C1", "無提醒團")

        // Then
        #expect(removedIdentifier == nil)
        let campaigns = try await service.fetchCampaigns()
        #expect(campaigns.isEmpty)
    }

    /// 驗證刪除不存在的開團時回傳 `nil`，且不影響任何訂單
    ///
    /// - Throws: 開團查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   開團儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   建立訂單時編號已存在丟出 `OrderError.identifierCollision(id:)`；
    ///   建立訂單查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   建立訂單儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    @Test
    func removeCampaign_識別值不存在_保留訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let campaignService = CampaignServiceTestSupport.makeService(database: database)
        let orderService = OrderServiceTestSupport.makeService(database: database)
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
