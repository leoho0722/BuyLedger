//
//  BLBarChartTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import Testing

@testable import BuyLedger

/// `BLBarChart` 的無障礙文字，涵蓋未提供時依環境 `locale` 解析預設 key 的行為
struct BLBarChartTests {

    /// 驗證英文 locale 下，未提供的無障礙文字依 `locale` 解析為英文預設文字
    @Test
    func titles_未提供標題_依英文環境解析預設文字() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLBarChart.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "Item")
        #expect(titles.axisY == "Value")
        #expect(titles.series == "Bar Chart")
    }

    /// 驗證正體中文 locale 下，未提供的無障礙文字依 `locale` 解析為正體中文預設文字
    @Test
    func titles_未提供標題_依正體中文環境解析預設文字() {
        // Given
        let locale = AppLanguage.traditionalChinese.locale

        // When
        let titles = BLBarChart.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "項目")
        #expect(titles.axisY == "數值")
        #expect(titles.series == "長條圖")
    }

    /// 驗證提供的無障礙文字原樣使用，不因 `locale` 改寫
    @Test
    func titles_提供標題_原樣使用() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLBarChart.ChartAccessibilityDescriptor.titles(
            axisX: "時段",
            axisY: "淨獲利",
            series: "月份走勢",
            locale: locale
        )

        // Then
        #expect(titles.axisX == "時段")
        #expect(titles.axisY == "淨獲利")
        #expect(titles.series == "月份走勢")
    }

    /// 驗證英文 locale 下，多筆資料的無障礙摘要以英文敘述帶入點數，以及最高與最低的標籤與金額描述
    @Test
    func summary_多筆資料_英文環境_回傳完整英文描述() {
        // Given
        let data = [
            BLBarChartValue(label: "Jan", value: 82, valueDescription: "NT$82"),
            BLBarChartValue(label: "Feb", value: 126, valueDescription: "NT$126"),
            BLBarChartValue(label: "Mar", value: 96, valueDescription: "NT$96"),
            BLBarChartValue(label: "Apr", value: 142, valueDescription: "NT$142"),
        ]

        // When
        let summary = BLBarChart.ChartAccessibilityDescriptor.summary(
            for: data,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(summary == "Bar chart, 4 periods in total, highest Apr NT$142, lowest Jan NT$82")
    }

    /// 驗證正體中文 locale 下，多筆資料的無障礙摘要以中文敘述帶入點數，以及最高與最低的標籤與金額描述
    @Test
    func summary_多筆資料_正體中文環境_回傳完整中文描述() {
        // Given
        let data = [
            BLBarChartValue(label: "1 月", value: 82, valueDescription: "NT$82"),
            BLBarChartValue(label: "2 月", value: 126, valueDescription: "NT$126"),
            BLBarChartValue(label: "3 月", value: 96, valueDescription: "NT$96"),
            BLBarChartValue(label: "4 月", value: 142, valueDescription: "NT$142"),
        ]

        // When
        let summary = BLBarChart.ChartAccessibilityDescriptor.summary(
            for: data,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(summary == "長條圖，共 4 個期間，最高 4 月 NT$142，最低 1 月 NT$82")
    }

    /// 驗證沒有資料時，英文 locale 下的無障礙摘要回傳英文無資料文字
    @Test
    func summary_沒有資料_英文環境_回傳無資料文字() {
        // Given
        let data: [BLBarChartValue] = []

        // When
        let summary = BLBarChart.ChartAccessibilityDescriptor.summary(
            for: data,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(summary == "Bar chart, no data")
    }

    /// 驗證沒有資料時，正體中文 locale 下的無障礙摘要回傳中文無資料文字
    @Test
    func summary_沒有資料_正體中文環境_回傳無資料文字() {
        // Given
        let data: [BLBarChartValue] = []

        // When
        let summary = BLBarChart.ChartAccessibilityDescriptor.summary(
            for: data,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(summary == "長條圖，目前沒有資料")
    }
}
