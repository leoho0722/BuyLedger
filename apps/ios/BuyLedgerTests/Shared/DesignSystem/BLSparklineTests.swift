//
//  BLSparklineTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import Testing

@testable import BuyLedger

/// `BLSparkline` 的預設文字，涵蓋依環境 `locale` 解析的行為
struct BLSparklineTests {

    /// 驗證英文 locale 下，未提供的無障礙標題依 `locale` 解析為英文預設文字
    @Test
    func titles_未提供標題_依英文環境解析預設文字() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLSparkline.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "Sequence")
        #expect(titles.axisY == "Value")
        #expect(titles.series == "Trend Chart")
    }

    /// 驗證正體中文 locale 下，未提供的無障礙標題依 `locale` 解析為正體中文預設文字
    @Test
    func titles_未提供標題_依正體中文環境解析預設文字() {
        // Given
        let locale = AppLanguage.traditionalChinese.locale

        // When
        let titles = BLSparkline.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "順序")
        #expect(titles.axisY == "數值")
        #expect(titles.series == "走勢圖")
    }

    /// 驗證提供的無障礙標題原樣使用，不因 `locale` 改寫
    @Test
    func titles_提供標題_原樣使用() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLSparkline.ChartAccessibilityDescriptor.titles(
            axisX: "日期",
            axisY: "獲利",
            series: "近一年",
            locale: locale
        )

        // Then
        #expect(titles.axisX == "日期")
        #expect(titles.axisY == "獲利")
        #expect(titles.series == "近一年")
    }

    /// 驗證英文 locale 下，預設資料點朗讀文字依 `locale` 解析為英文，不寫死正體中文
    @Test
    func defaultPointOrdinalDescription_英文環境_顯示英文順位() {
        // Given
        let ordinal = 2

        // When
        let text = BLSparkline.ChartAccessibilityDescriptor.defaultPointOrdinalDescription(
            ordinal,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(text == "Point 2")
    }

    /// 驗證正體中文 locale 下，預設資料點朗讀文字依 `locale` 解析為正體中文
    @Test
    func defaultPointOrdinalDescription_正體中文環境_顯示中文順位() {
        // Given
        let ordinal = 2

        // When
        let text = BLSparkline.ChartAccessibilityDescriptor.defaultPointOrdinalDescription(
            ordinal,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(text == "第 2 筆")
    }
}
