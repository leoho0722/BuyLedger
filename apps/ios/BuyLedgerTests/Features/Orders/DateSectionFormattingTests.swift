//
//  DateSectionFormattingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderFormatters` 與 `CampaignFormatters` 的單元測試，日期的時區與曆法由注入的行事曆決定
struct DateSectionFormattingTests {

    /// 驗證午夜後半小時以注入時區判定日期，與參照日同年時，日標題只顯示該日的月日與星期，不變成裝置時區的前一天
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func daySectionTitle_注入時區午夜後半小時_顯示當天月日星期() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let components = DateComponents(
            year: 2026,
            month: 4,
            day: 26,
            hour: 0,
            minute: 30
        )
        let date = try #require(calendar.date(from: components))
        let referenceDate = try #require(calendar.date(byAdding: .day, value: 3, to: date))

        // When
        let title = OrderFormatters.daySectionTitle(
            for: date,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(title == "4月26日週日")
    }

    /// 驗證月初午夜後半小時以注入時區仍屬當月，年月區段標題顯示該時區的年與月，不變成裝置時區的上個月
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func sectionTitle_年月區段_顯示注入時區的當年當月() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let components = DateComponents(
            year: 2026,
            month: 5,
            day: 1,
            hour: 0,
            minute: 30
        )
        let date = try #require(calendar.date(from: components))
        let context = CampaignDateContext(now: date, calendar: calendar)
        let locale = Locale(identifier: "zh-Hant")

        // When
        let title = CampaignFormatters.sectionTitle(
            .yearMonth(date),
            context: context,
            locale: locale
        )

        // Then
        #expect(title == "2026年5月")
    }

    /// 驗證月初午夜後半小時以注入時區仍屬當月，月區段標題顯示該月，不變成裝置時區的上個月
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func sectionTitle_月區段_顯示注入時區的當月() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let components = DateComponents(
            year: 2026,
            month: 5,
            day: 1,
            hour: 0,
            minute: 30
        )
        let date = try #require(calendar.date(from: components))
        let context = CampaignDateContext(now: date, calendar: calendar)
        let locale = Locale(identifier: "zh-Hant")

        // When
        let title = CampaignFormatters.sectionTitle(.month(date), context: context, locale: locale)

        // Then
        #expect(title == "5月")
    }

    /// 驗證完整時間以注入行事曆的時區呈現，輸出補零的西曆年月日與二十四小時制時分秒，不換算成裝置時區
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func fullTimestamp_注入時區下午兩點半_顯示當地完整時間() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let components = DateComponents(
            year: 2026,
            month: 4,
            day: 26,
            hour: 14,
            minute: 30,
            second: 0
        )
        let date = try #require(calendar.date(from: components))

        // When
        let timestamp = OrderFormatters.fullTimestamp(
            date,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(timestamp == "2026/04/26 14:30:00")
    }

    /// 驗證注入民國曆行事曆時，完整時間仍以西曆印出年月日，年份為 2026 而非民國年
    ///
    /// - Throws: 時區建立失敗時丟出錯誤
    /// - Note: 日期以時間戳記給定，不用 `calendar.date(from:)`，它會把 2026 當成民國年
    @Test
    func fullTimestamp_民國曆行事曆_仍以西曆顯示年月日() throws {
        // Given
        var calendar = Calendar(identifier: .republicOfChina)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Taipei"))
        let date = Date(timeIntervalSince1970: 1_777_185_000)

        // When
        let timestamp = OrderFormatters.fullTimestamp(
            date,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(timestamp == "2026/04/26 14:30:00")
    }
}
