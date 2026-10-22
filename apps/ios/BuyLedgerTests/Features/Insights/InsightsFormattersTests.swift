//
//  InsightsFormattersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證分析頁格式化的走勢文字、標籤與圖表值
struct InsightsFormattersTests {

    // MARK: - Properties

    /// 百分比與走勢文字使用的正體中文 locale，與分析頁既有測試一致
    private static let traditionalChinese = AppLanguage.traditionalChinese.locale

    /// 金額描述使用的英文 locale，與 `BLFormattersTests` 既有慣例一致
    private static let english = AppLanguage.english.locale

    /// 解析字面值 `Decimal` 用的固定 locale，避免十進位字串解析受執行環境影響
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// 比值不為負時顯示上升箭頭與絕對值百分比，本期與上期相等 (比值為零) 也歸為上升
    ///
    /// - Parameters:
    ///   - ratioText: 比值的十進位字串
    ///   - expected: 預期顯示的文字
    /// - Throws: 比值字串無法解析時丟出
    @Test(arguments: [
        (ratioText: "1.5", expected: "↑ 150.0%"),
        (ratioText: "0.5", expected: "↑ 50.0%"),
        (ratioText: "0", expected: "↑ 0.0%"),
    ])
    func trendDelta_比值不為負_顯示上升與百分比(ratioText: String, expected: String) throws {
        // Given
        let ratio = try #require(Decimal(string: ratioText, locale: Self.posixLocale))

        // When
        let delta = InsightsFormatters.trendDelta(ratio, locale: Self.traditionalChinese)

        // Then
        #expect(delta == expected)
    }

    /// 比值為負時顯示下降箭頭與絕對值百分比
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

    /// 沒有比值時顯示比較說明的本地化 key
    @Test
    func trendDelta_沒有比值_顯示比較說明() {
        // Given
        let ratio: Decimal? = nil

        // When
        let delta = InsightsFormatters.trendDelta(ratio, locale: Self.traditionalChinese)

        // Then
        #expect(delta == "insights.chart.label.comparison")
    }

    /// 走勢段轉成長條圖資料時沿用原標籤，數值為獲利的 `Double`，描述為 NT$ 金額，負值保留負號
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

    /// 排行標題由名次與名稱以點加空格組成
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

    /// 熱力圖週次標籤為大寫 W 加上由 1 起算的週次
    @Test
    func weekLabel_週次_輸出W加數字() {
        // Given
        let weekNumber = 3

        // When
        let label = InsightsFormatters.weekLabel(weekNumber)

        // Then
        #expect(label == "W3")
    }

    /// 正體中文下的星期縮寫由週一排到週日
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

    /// 英文下的星期縮寫由週一排到週日
    @Test
    func weekdayLabels_英文_由週一排到週日() {
        // Given
        let calendar = TestDependencies.fixedCalendar

        // When
        let labels = InsightsFormatters.weekdayLabels(calendar: calendar, locale: Self.english)

        // Then
        #expect(labels == ["M", "T", "W", "T", "F", "S", "S"])
    }

    /// 成本區塊轉成圈狀圖區段時保留順序，金額轉為 `Double`、附上金額描述與語意色調
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
