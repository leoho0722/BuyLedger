//
//  InsightsFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `InsightsFormatters` 的單元測試，涵蓋走勢文字、標籤與圖表值的格式化
struct InsightsFormattersTests {

    // MARK: - Properties

    /// 百分比與走勢文字使用的正體中文 locale，與分析頁既有測試一致
    private static let traditionalChinese = AppLanguage.traditionalChinese.locale

    /// 金額描述使用的英文 locale，與 `BLFormattersTests` 既有慣例一致
    private static let english = AppLanguage.english.locale

    /// 解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// 驗證比值不為負時，`trendDelta` 顯示上升箭頭與絕對值百分比，比值為零 (本期與上期相等) 也歸為上升
    ///
    /// - Parameter scenario: 比值的十進位字串與預期顯示的文字
    /// - Throws: 比值字串無法解析時丟出
    @Test(arguments: [
        TrendDeltaScenario(ratioText: "1.5", expected: "↑ 150.0%"),
        TrendDeltaScenario(ratioText: "0.5", expected: "↑ 50.0%"),
        TrendDeltaScenario(ratioText: "0", expected: "↑ 0.0%"),
    ])
    func trendDelta_比值不為負_顯示上升與百分比(scenario: TrendDeltaScenario) throws {
        // Given
        let ratio = try #require(Decimal(string: scenario.ratioText, locale: Self.posixLocale))

        // When
        let delta = InsightsFormatters.trendDelta(ratio, locale: Self.traditionalChinese)

        // Then
        #expect(delta == scenario.expected)
    }

    /// 驗證變化比值為 -1 時，`trendDelta` 在正體中文環境顯示「↓ 100.0%」，百分比取絕對值
    ///
    /// - Throws: 比值字串無法解析時丟出
    @Test
    func trendDelta_比值為負_顯示下降與絕對值百分比() throws {
        // Given
        let ratio = try #require(Decimal(string: "-1", locale: Self.posixLocale))

        // When
        let delta = InsightsFormatters.trendDelta(ratio, locale: Self.traditionalChinese)

        // Then
        #expect(delta == "↓ 100.0%")
    }

    /// 驗證沒有比值時，`trendDelta` 回傳比較說明的本地化鍵，不產生百分比
    @Test
    func trendDelta_沒有比值_顯示比較說明() {
        // Given
        let ratio: Decimal? = nil

        // When
        let delta = InsightsFormatters.trendDelta(ratio, locale: Self.traditionalChinese)

        // Then
        #expect(delta == "insights.chart.label.comparison")
    }

    /// 驗證走勢段轉成長條圖資料時沿用原標籤，數值為獲利的 `Double`，描述為 NT$ 金額，負值保留負號
    @Test
    func trendBars_走勢段_沿用標籤並轉為數值與金額描述() {
        // Given
        let buckets = [
            InsightsTrendBucket(label: "05/13", profit: 1_000),
            InsightsTrendBucket(label: "05/14", profit: -250),
        ]

        // When
        let bars = InsightsFormatters.trendBars(buckets, locale: Self.english)

        // Then
        #expect(bars.map(\.label) == ["05/13", "05/14"])
        #expect(bars.map(\.value) == [1_000, -250])
        #expect(bars.map(\.valueDescription) == ["NT$1,000", "-NT$250"])
    }

    /// 驗證第 2 名的開團經 `rankTitle` 格式化後，標題為名次、點、一個半形空格與開團名稱
    @Test
    func rankTitle_名次與名稱_以點與空格相連() {
        // Given
        let rank = 2
        let name = "A團"

        // When
        let title = InsightsFormatters.rankTitle(rank: rank, name: name)

        // Then
        #expect(title == "2. A團")
    }

    /// 驗證 `weekLabel` 輸出大寫 W 加上由 1 起算的週次，第 3 週為 W3
    @Test
    func weekLabel_週次_輸出W加數字() {
        // Given
        let weekNumber = 3

        // When
        let label = InsightsFormatters.weekLabel(weekNumber)

        // Then
        #expect(label == "W3")
    }

    /// 驗證正體中文下，`weekdayLabels` 的星期縮寫由週一排到週日
    @Test
    func weekdayLabels_正體中文_由週一排到週日() {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let locale = Self.traditionalChinese

        // When
        let labels = InsightsFormatters.weekdayLabels(calendar: calendar, locale: locale)

        // Then
        #expect(labels == ["一", "二", "三", "四", "五", "六", "日"])
    }

    /// 驗證英文下，`weekdayLabels` 的星期縮寫由週一排到週日
    @Test
    func weekdayLabels_英文_由週一排到週日() {
        // Given
        let calendar = TestDependencies.fixedCalendar

        // When
        let labels = InsightsFormatters.weekdayLabels(calendar: calendar, locale: Self.english)

        // Then
        #expect(labels == ["M", "T", "W", "T", "F", "S", "S"])
    }

    /// 驗證成本區塊轉成圈狀圖區段時，`costDonutSlices` 保留順序，金額轉為 `Double`，附上金額描述與語意色調
    @Test
    func costDonutSlices_成本區塊_保留順序並換算金額與色調() {
        // Given
        let segments = [
            InsightsCostSegment(label: "orders.detail.label.itemCost", value: 300, tone: .accent),
            InsightsCostSegment(label: "orders.detail.label.fees", value: 1_000, tone: .orange),
        ]

        // When
        let slices = InsightsFormatters.costDonutSlices(segments, locale: Self.english)

        // Then
        #expect(slices.map(\.label) == ["orders.detail.label.itemCost", "orders.detail.label.fees"])
        #expect(slices.map(\.value) == [300, 1_000])
        #expect(slices.map(\.valueDescription) == ["NT$300", "NT$1,000"])
        #expect(slices.map(\.tone) == [.accent, .orange])
    }
}

// MARK: - Nested Types

extension InsightsFormattersTests {

    /// 一組比值字串與預期顯示的趨勢文字
    struct TrendDeltaScenario: Sendable {

        /// 比值的十進位字串
        let ratioText: String

        /// 預期顯示的文字
        let expected: String
    }
}
