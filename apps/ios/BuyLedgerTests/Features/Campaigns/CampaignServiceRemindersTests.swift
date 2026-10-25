//
//  CampaignServiceRemindersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CampaignService` 的單元測試，涵蓋提醒連結的儲存、覆寫與移除
struct CampaignServiceRemindersTests {

    /// 驗證以新的開團識別值儲存提醒連結後，讀回的連結內容與儲存時相同
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func saveReminderLink_新的開團識別值_新增提醒連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let firstReminderTimestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )

        // When
        try await service.saveReminderLink("C1", firstLink)

        // Then
        let links = try await service.fetchReminderLinks()
        #expect(links == ["C1": firstLink])
    }

    /// 驗證相同開團識別值再次儲存時，提醒事件識別值與提醒時間都換成新值，且不新增第二筆
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveReminderLink_開團識別值相同_覆寫原連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let firstReminderTimestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let updatedReminderTimestamp = Date(timeIntervalSince1970: 1_777_226_400)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let updatedLink = CampaignReminderLink(
            eventIdentifier: "EVT-2",
            reminderTimestamp: updatedReminderTimestamp
        )
        try await service.saveReminderLink("C1", firstLink)
        let initialLinks = try await service.fetchReminderLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.saveReminderLink("C1", updatedLink)

        // Then
        let links = try await service.fetchReminderLinks()
        #expect(links == ["C1": updatedLink])
    }

    /// 驗證以不同開團識別值儲存時新增另一筆連結，既有連結的內容維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveReminderLink_開團識別值不同_新增另一筆連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let firstReminderTimestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let secondReminderTimestamp = Date(timeIntervalSince1970: 1_777_626_000)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let secondLink = CampaignReminderLink(
            eventIdentifier: "EVT-3",
            reminderTimestamp: secondReminderTimestamp
        )
        try await service.saveReminderLink("C1", firstLink)
        let initialLinks = try await service.fetchReminderLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.saveReminderLink("C2", secondLink)

        // Then
        let links = try await service.fetchReminderLinks()
        #expect(links == ["C1": firstLink, "C2": secondLink])
    }

    /// 驗證移除指定開團識別值的提醒連結時，只移除相符的連結，其他連結保留
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func removeReminderLink_指定識別值_只移除相符連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let firstReminderTimestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let secondReminderTimestamp = Date(timeIntervalSince1970: 1_777_626_000)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let secondLink = CampaignReminderLink(
            eventIdentifier: "EVT-2",
            reminderTimestamp: secondReminderTimestamp
        )
        try await service.saveReminderLink("C1", firstLink)
        try await service.saveReminderLink("C2", secondLink)
        let initialLinks = try await service.fetchReminderLinks()
        try #require(initialLinks == ["C1": firstLink, "C2": secondLink])

        // When
        try await service.removeReminderLink("C1")

        // Then
        let links = try await service.fetchReminderLinks()
        #expect(links == ["C2": secondLink])
    }

    /// 驗證移除不存在的開團識別值時不會出錯，既有提醒連結的內容維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func removeReminderLink_識別值不存在_保留既有連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CampaignServiceTestSupport.makeService(database: database)
        let firstReminderTimestamp = Date(timeIntervalSince1970: 1_776_675_600)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        try await service.saveReminderLink("C1", firstLink)
        let initialLinks = try await service.fetchReminderLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.removeReminderLink("C-nonexistent")

        // Then
        let links = try await service.fetchReminderLinks()
        #expect(links == ["C1": firstLink])
    }
}
