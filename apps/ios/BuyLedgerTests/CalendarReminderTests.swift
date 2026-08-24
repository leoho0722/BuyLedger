//
//  CalendarReminderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/11.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證開團提醒的日期、標題與連結儲存
@MainActor
struct CalendarReminderTests {
    
    // MARK: - Tests
    
    @Test func reminderTitleWrapsNameInCornerBrackets() {
        let campaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: Self.day(month: 4, day: 1, hour: 0),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        
        #expect(campaign.reminderTitle == "「四月團」訂購提醒")
    }
    
    @Test func repositoryRoundTripsLinks() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let repository = CampaignReminderRepository.live(container: container)
        
        let ts1 = Self.day(month: 4, day: 20, hour: 9)
        let ts2 = Self.day(month: 4, day: 26, hour: 18)
        let ts3 = Self.day(month: 5, day: 1, hour: 9)
        
        try await repository.saveLink(
            "C1",
            CampaignReminderLink(eventIdentifier: "EVT-1", reminderTimestamp: ts1)
        )
        var links = try await repository.fetchLinks()
        #expect(
            links == [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-1",
                    reminderTimestamp: ts1
                )
            ]
        )
        
        // 相同 campaignID 會更新，不同 campaignID 會新增。
        try await repository.saveLink(
            "C1",
            CampaignReminderLink(eventIdentifier: "EVT-2", reminderTimestamp: ts2)
        )
        try await repository.saveLink(
            "C2",
            CampaignReminderLink(eventIdentifier: "EVT-3", reminderTimestamp: ts3)
        )
        links = try await repository.fetchLinks()
        #expect(
            links == [
                "C1": CampaignReminderLink(
                    eventIdentifier: "EVT-2",
                    reminderTimestamp: ts2
                ),
                "C2": CampaignReminderLink(
                    eventIdentifier: "EVT-3",
                    reminderTimestamp: ts3
                )
            ]
        )
        
        // 移除單一連結
        try await repository.removeLink("C1")
        links = try await repository.fetchLinks()
        #expect(
            links == [
                "C2": CampaignReminderLink(
                    eventIdentifier: "EVT-3",
                    reminderTimestamp: ts3
                )
            ]
        )
        
        // 移除不存在的連結為 no-op
        try await repository.removeLink("C-nonexistent")
        links = try await repository.fetchLinks()
        #expect(
            links == [
                "C2": CampaignReminderLink(
                    eventIdentifier: "EVT-3",
                    reminderTimestamp: ts3
                )
            ]
        )
    }
    
    // MARK: - Helper
    
    /// 固定使用 Gregorian／UTC 行事曆
    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()
    
    /// 建立 2026 年指定日期與時間 (UTC)
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 日期
    ///   - hour: 小時
    /// - Returns: 指定日期與時間 UTC 的時間值
    static func day(
        month: Int,
        day: Int,
        hour: Int
    ) -> Date {
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
