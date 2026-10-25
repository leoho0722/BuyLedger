//
//  BLFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/30.
//

import Foundation
import Testing

@testable import BuyLedger

/// ``BLFormatters`` 的單元測試，涵蓋既有的金額、百分比與日期呈現結果
struct BLFormattersTests {

    // MARK: - Properties

    /// 固定為 UTC 中午的參考日期，避免裝置時區讓日期跨日
    private static let shortDateReferenceDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = DateComponents(
            year: 2026,
            month: 4,
            day: 30,
            hour: 12
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }()

    /// 測試固定使用的呈現 locale，與 ``OrderCalculationTests`` 既有慣例一致
    private static let locale = Locale(identifier: "en")

    /// 解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// 驗證正數金額以新台幣格式呈現，例如 1,234 顯示為 NT$1,234
    @Test
    func twd_正數金額_以新台幣格式呈現() {
        // Given
        let amount = Decimal(1_234)

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "NT$1,234")
    }

    /// 驗證零金額以新台幣格式呈現為 NT$0
    @Test
    func twd_零金額_以新台幣格式呈現() {
        // Given
        let amount = Decimal(0)

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "NT$0")
    }

    /// 驗證負數金額以新台幣格式呈現，負號位於幣別前
    @Test
    func twd_負數金額_以新台幣格式呈現() {
        // Given
        let amount = Decimal(-567)

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "-NT$567")
    }

    /// 驗證大額金額以千分位逗號分隔
    @Test
    func twd_大額金額_以新台幣格式呈現() {
        // Given
        let amount = Decimal(12_345_678)

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "NT$12,345,678")
    }

    /// 驗證可選金額為 1,234 時，在英文環境呈現為「NT$1,234」
    @Test
    func twd_有值的可選金額_與非可選版本結果相同() {
        // Given
        let amount: Decimal? = 1_234

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "NT$1,234")
    }

    /// 驗證可選金額為 `nil` 時，金額顯示為占位符號，不顯示數字
    @Test
    func twd_可選金額為空_顯示占位符號() {
        // Given
        let amount: Decimal? = nil

        // When
        let formatted = BLFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(formatted == "—")
    }

    /// 驗證比例 0.654 在英文環境呈現為「65.4%」，換算為百分比並保留一位小數
    @Test
    func percent_正比例_顯示一位小數百分比() {
        // Given
        let ratio = Decimal(string: "0.654", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(ratio, locale: Self.locale)

        // Then
        #expect(formatted == "65.4%")
    }

    /// 驗證比例為零時，在英文環境仍保留一位小數，呈現為「0.0%」
    @Test
    func percent_零比例_顯示一位小數百分比() {
        // Given
        let ratio = Decimal(0)

        // When
        let formatted = BLFormatters.percent(ratio, locale: Self.locale)

        // Then
        #expect(formatted == "0.0%")
    }

    /// 驗證比例為 -0.123 時，在英文環境保留負號，呈現為「-12.3%」
    @Test
    func percent_負比例_顯示一位小數百分比() {
        // Given
        let ratio = Decimal(string: "-0.123", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(ratio, locale: Self.locale)

        // Then
        #expect(formatted == "-12.3%")
    }

    /// 驗證比例 12.5 在英文環境呈現為「1,250.0%」，保留千分位分隔與一位小數
    @Test
    func percent_超過百分之一百的比例_顯示千分位與一位小數() {
        // Given
        let ratio = Decimal(string: "12.5", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(ratio, locale: Self.locale)

        // Then
        #expect(formatted == "1,250.0%")
    }

    /// 驗證已是百分比尺度的 65.4 直接呈現為「65.4%」，不再放大一百倍
    @Test
    func percent_已是百分比尺度的正數_顯示一位小數百分比() {
        // Given
        let value = Decimal(string: "65.4", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(scaled: value, locale: Self.locale)

        // Then
        #expect(formatted == "65.4%")
    }

    /// 驗證已是百分比尺度的零在英文環境呈現為「0.0%」，保留一位小數
    @Test
    func percent_已是百分比尺度的零_顯示一位小數百分比() {
        // Given
        let value = Decimal(0)

        // When
        let formatted = BLFormatters.percent(scaled: value, locale: Self.locale)

        // Then
        #expect(formatted == "0.0%")
    }

    /// 驗證已是百分比尺度的 -12.3 在英文環境呈現為「-12.3%」，保留負號且不再放大
    @Test
    func percent_已是百分比尺度的負數_顯示一位小數百分比() {
        // Given
        let value = Decimal(string: "-12.3", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(scaled: value, locale: Self.locale)

        // Then
        #expect(formatted == "-12.3%")
    }

    /// 驗證已是百分比尺度的 999.9 在英文環境直接呈現為「999.9%」，不再放大一百倍
    @Test
    func percent_已是百分比尺度的大數值_顯示一位小數百分比() {
        // Given
        let value = Decimal(string: "999.9", locale: Self.posixLocale) ?? 0

        // When
        let formatted = BLFormatters.percent(scaled: value, locale: Self.locale)

        // Then
        #expect(formatted == "999.9%")
    }

    /// 驗證 4 月 30 日在台灣中文與英文 locale 下，月日短日期都呈現為「4/30」
    ///
    /// - Parameter scenario: 用於呈現的 locale 與預期的月日格式字串
    @Test(arguments: [
        ShortDateCase(localeIdentifier: "zh_TW", expected: "4/30"),
        ShortDateCase(localeIdentifier: "en", expected: "4/30"),
    ])
    func shortDate_依地區設定_顯示月日短日期(scenario: ShortDateCase) {
        // Given
        let date = Self.shortDateReferenceDate
        let locale = Locale(identifier: scenario.localeIdentifier)

        // When
        let formatted = BLFormatters.shortDate(date, locale: locale)

        // Then
        #expect(formatted == scenario.expected)
    }

    /// 驗證 `OrderFormatters` 的金額呈現為 NT$1,234
    @Test
    func twd_畫面格式化器_委派共用金額格式化器() {
        // Given
        let amount = Decimal(1_234)

        // When
        let orderFormatted = OrderFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(orderFormatted == "NT$1,234")
    }

    /// 驗證 `CampaignFormatters` 的金額呈現為 NT$1,234
    @Test
    func twd_開團畫面格式化器_呈現新台幣金額() {
        // Given
        let amount = Decimal(1_234)

        // When
        let campaignFormatted = CampaignFormatters.twd(amount, locale: Self.locale)

        // Then
        #expect(campaignFormatted == "NT$1,234")
    }

    /// 驗證 `OrderFormatters` 的百分比呈現為 65.4%
    @Test
    func percent_畫面格式化器_委派共用百分比格式化器() {
        // Given
        let ratio = Decimal(string: "0.654", locale: Self.posixLocale) ?? 0

        // When
        let formatted = OrderFormatters.percent(ratio, locale: Self.locale)

        // Then
        #expect(formatted == "65.4%")
    }

    /// 驗證同一天與前一天的區段標題，在英文顯示 Today 與 Yesterday，在正體中文顯示「今天」與「昨天」
    ///
    /// - Parameter scenario: 要呈現的日期 (今天或昨天)、locale 與預期標題
    @Test(arguments: [
        DaySectionTitleCase(isYesterday: false, localeIdentifier: "en", expected: "Today"),
        DaySectionTitleCase(isYesterday: false, localeIdentifier: "zh-Hant", expected: "今天"),
        DaySectionTitleCase(isYesterday: true, localeIdentifier: "en", expected: "Yesterday"),
        DaySectionTitleCase(isYesterday: true, localeIdentifier: "zh-Hant", expected: "昨天"),
    ])
    func daySectionTitle_今天與昨天_依Locale本地化(scenario: DaySectionTitleCase) {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let now = Date(timeIntervalSince1970: 1_777_185_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let day = scenario.isYesterday ? yesterday : now

        // When
        let title = BLFormatters.daySectionTitle(
            for: day,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: scenario.localeIdentifier)
        )

        // Then
        #expect(title == scenario.expected)
    }
}

// MARK: - Nested Types

extension BLFormattersTests {

    /// 月日短日期的測試案例：呈現用的 locale 與預期字串
    struct ShortDateCase: Sendable {

        /// 呈現用的 locale 識別字
        let localeIdentifier: String

        /// 預期的月日格式字串
        let expected: String
    }

    /// 日區段標題的測試案例：要呈現的是否為昨天、locale 與預期標題
    struct DaySectionTitleCase: Sendable {

        /// 是否為昨天，`false` 代表今天
        let isYesterday: Bool

        /// 呈現用的 locale 識別字
        let localeIdentifier: String

        /// 預期的區段標題
        let expected: String
    }
}
