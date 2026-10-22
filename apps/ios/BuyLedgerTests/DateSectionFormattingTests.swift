//
//  DateSectionFormattingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation
import Testing

@testable import BuyLedger

/// 日期區段標題與完整時間使用注入行事曆時區的測試
struct DateSectionFormattingTests {

    /// 同年日標題以注入時區的月日與星期呈現，不套用裝置的前一天
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func daySectionTitle_注入時區午夜後半小時_顯示當天月日星期() throws(any Error) {
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

    /// 注入時區的月初午夜後半小時仍屬當月，年月區段以該時區顯示當年當月，不套用裝置時區的上個月
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func sectionTitle_年月區段_顯示注入時區的當年當月() throws(any Error) {
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

    /// 注入時區的月初午夜後半小時仍屬當月，月區段以該時區顯示當月，不套用裝置時區的上個月
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func sectionTitle_月區段_顯示注入時區的當月() throws(any Error) {
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

    /// 完整時間以注入時區的年月日與時分秒呈現
    ///
    /// - Throws: 時區或測試日期建立失敗時丟出錯誤
    @Test
    func fullTimestamp_注入時區下午兩點半_顯示當地完整時間() throws(any Error) {
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

    /// 注入民國曆行事曆時，完整時間的年月日仍以西曆印出
    ///
    /// - Throws: 時區建立失敗時丟出錯誤
    /// - Note: 日期以時間戳記給定，不用 `calendar.date(from:)`，它會把 2026 當成民國年
    @Test
    func fullTimestamp_民國曆行事曆_仍以西曆顯示年月日() throws(any Error) {
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
