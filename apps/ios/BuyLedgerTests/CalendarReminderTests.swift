//
//  CalendarReminderTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/11.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團提醒的標題格式
struct CalendarReminderTests {

    // MARK: - Tests

    /// 行事曆事件標題固定為「開團名稱」訂購提醒，讓使用者在行事曆認得是哪一團的提醒
    @Test
    func reminderTitle_開團名稱_引號包住名稱後接訂購提醒() {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: Self.day(month: 4, day: 1, hour: 0),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )

        // When
        let title = campaign.reminderTitle

        // Then
        #expect(title == "「四月團」訂購提醒")
    }
}

// MARK: - Private Method

private extension CalendarReminderTests {

    /// 建立 2026 年指定日期與時間 (UTC)
    ///
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 日期
    ///   - hour: 小時
    /// - Returns: 指定日期與時間 UTC 的時間值
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
