//
//  CampaignReminderServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團提醒連結 Service 的持久化行為
struct CampaignReminderServiceTests {

    // MARK: - Tests

    /// 新增提醒連結後讀回相同內容
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    @Test
    func saveLink_新的開團識別值_新增提醒連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let firstReminderTimestamp = Self.day(month: 4, day: 20, hour: 9)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )

        // When
        try await service.saveLink("C1", firstLink)

        // Then
        let links = try await service.fetchLinks()
        #expect(links == ["C1": firstLink])
    }

    /// 相同開團識別值再次儲存時，提醒事件識別值與提醒時間都換成新值，且不新增第二筆
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveLink_開團識別值相同_覆寫原連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let firstReminderTimestamp = Self.day(month: 4, day: 20, hour: 9)
        let updatedReminderTimestamp = Self.day(month: 4, day: 26, hour: 18)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let updatedLink = CampaignReminderLink(
            eventIdentifier: "EVT-2",
            reminderTimestamp: updatedReminderTimestamp
        )
        try await service.saveLink("C1", firstLink)
        let initialLinks = try await service.fetchLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.saveLink("C1", updatedLink)

        // Then
        let links = try await service.fetchLinks()
        #expect(links == ["C1": updatedLink])
    }

    /// 不同開團識別值儲存時新增另一筆連結，既有連結的內容維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func saveLink_開團識別值不同_新增另一筆連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let firstReminderTimestamp = Self.day(month: 4, day: 20, hour: 9)
        let secondReminderTimestamp = Self.day(month: 5, day: 1, hour: 9)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let secondLink = CampaignReminderLink(
            eventIdentifier: "EVT-3",
            reminderTimestamp: secondReminderTimestamp
        )
        try await service.saveLink("C1", firstLink)
        let initialLinks = try await service.fetchLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.saveLink("C2", secondLink)

        // Then
        let links = try await service.fetchLinks()
        #expect(links == ["C1": firstLink, "C2": secondLink])
    }

    /// 移除一筆提醒連結時保留其他連結
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func removeLink_指定識別值_只移除相符連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let firstReminderTimestamp = Self.day(month: 4, day: 20, hour: 9)
        let secondReminderTimestamp = Self.day(month: 5, day: 1, hour: 9)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        let secondLink = CampaignReminderLink(
            eventIdentifier: "EVT-2",
            reminderTimestamp: secondReminderTimestamp
        )
        try await service.saveLink("C1", firstLink)
        try await service.saveLink("C2", secondLink)
        let initialLinks = try await service.fetchLinks()
        try #require(initialLinks == ["C1": firstLink, "C2": secondLink])

        // When
        try await service.removeLink("C1")

        // Then
        let links = try await service.fetchLinks()
        #expect(links == ["C2": secondLink])
    }

    /// 移除不存在的開團識別值時不會出錯，既有提醒連結的內容維持不變
    ///
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   前置條件不成立時由 `#require` 丟出測試斷言錯誤
    @Test
    func removeLink_識別值不存在_保留既有連結() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let firstReminderTimestamp = Self.day(month: 4, day: 20, hour: 9)
        let firstLink = CampaignReminderLink(
            eventIdentifier: "EVT-1",
            reminderTimestamp: firstReminderTimestamp
        )
        try await service.saveLink("C1", firstLink)
        let initialLinks = try await service.fetchLinks()
        try #require(initialLinks == ["C1": firstLink])

        // When
        try await service.removeLink("C-nonexistent")

        // Then
        let links = try await service.fetchLinks()
        #expect(links == ["C1": firstLink])
    }
}

// MARK: - Internal Method

extension CampaignReminderServiceTests {

    /// 以注入的資料庫建立正式 `CampaignReminderService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 已擷取資料庫依賴的 `CampaignReminderService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> CampaignReminderService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CampaignReminderService.liveValue
        }
    }
}

// MARK: - Private Method

private extension CampaignReminderServiceTests {

    /// 建立 2026 年指定日期與時間 (UTC)
    ///
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 日期
    ///   - hour: 小時
    /// - Returns: 指定日期與時間的 UTC 時間值；組不出日期時回退為 1970-01-01 (Unix epoch)
    static func day(month: Int, day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = hour
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
