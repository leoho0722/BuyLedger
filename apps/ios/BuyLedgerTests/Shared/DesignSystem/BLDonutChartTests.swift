//
//  BLDonutChartTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/8.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// `BLDonutChart` 的無障礙文字，涵蓋未提供時依環境 `locale` 解析預設 key 的行為
struct BLDonutChartTests {

    /// 驗證英文 locale 下，未提供的無障礙文字依 `locale` 解析為英文預設文字
    @Test
    func titles_未提供標題_依英文環境解析預設文字() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLDonutChart.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "Category")
        #expect(titles.axisY == "Share")
        #expect(titles.series == "Donut Chart")
    }

    /// 驗證正體中文 locale 下，未提供的無障礙文字依 `locale` 解析為正體中文預設文字
    @Test
    func titles_未提供標題_依正體中文環境解析預設文字() {
        // Given
        let locale = AppLanguage.traditionalChinese.locale

        // When
        let titles = BLDonutChart.ChartAccessibilityDescriptor.titles(
            axisX: nil,
            axisY: nil,
            series: nil,
            locale: locale
        )

        // Then
        #expect(titles.axisX == "類別")
        #expect(titles.axisY == "占比")
        #expect(titles.series == "圈狀圖")
    }

    /// 驗證提供的無障礙文字原樣使用，不因 `locale` 改寫
    @Test
    func titles_提供標題_原樣使用() {
        // Given
        let locale = AppLanguage.english.locale

        // When
        let titles = BLDonutChart.ChartAccessibilityDescriptor.titles(
            axisX: "餐飲",
            axisY: "金額",
            series: "成本結構",
            locale: locale
        )

        // Then
        #expect(titles.axisX == "餐飲")
        #expect(titles.axisY == "金額")
        #expect(titles.series == "成本結構")
    }

    /// 驗證英文 locale 下，多筆區段的無障礙摘要以英文敘述帶入類別數，以及占比最高的名稱與金額描述
    @Test
    func summary_多筆區段_英文環境_回傳完整英文描述() {
        // Given
        let segments = [
            BLDonutSegment(
                label: "Dining",
                value: 420,
                color: .blAccent,
                valueDescription: "NT$420"
            ),
            BLDonutSegment(
                label: "Transport",
                value: 180,
                color: .blGreen,
                valueDescription: "NT$180"
            ),
            BLDonutSegment(
                label: "Shopping",
                value: 300,
                color: .blOrange,
                valueDescription: "NT$300"
            ),
        ]

        // When
        let summary = BLDonutChart.ChartAccessibilityDescriptor.summary(
            for: segments,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(summary == "Donut chart, 3 categories in total, highest share is Dining NT$420")
    }

    /// 驗證正體中文 locale 下，多筆區段的無障礙摘要以中文敘述帶入類別數，以及占比最高的名稱與金額描述
    @Test
    func summary_多筆區段_正體中文環境_回傳完整中文描述() {
        // Given
        let segments = [
            BLDonutSegment(
                label: "餐飲",
                value: 420,
                color: .blAccent,
                valueDescription: "NT$420"
            ),
            BLDonutSegment(
                label: "交通",
                value: 180,
                color: .blGreen,
                valueDescription: "NT$180"
            ),
            BLDonutSegment(
                label: "購物",
                value: 300,
                color: .blOrange,
                valueDescription: "NT$300"
            ),
        ]

        // When
        let summary = BLDonutChart.ChartAccessibilityDescriptor.summary(
            for: segments,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(summary == "圈狀圖，共 3 個類別，占比最高為 餐飲 NT$420")
    }

    /// 驗證沒有區段時，英文 locale 下的無障礙摘要回傳英文無資料文字
    @Test
    func summary_沒有區段_英文環境_回傳無資料文字() {
        // Given
        let segments: [BLDonutSegment] = []

        // When
        let summary = BLDonutChart.ChartAccessibilityDescriptor.summary(
            for: segments,
            locale: AppLanguage.english.locale
        )

        // Then
        #expect(summary == "Donut chart, no data")
    }

    /// 驗證沒有區段時，正體中文 locale 下的無障礙摘要回傳中文無資料文字
    @Test
    func summary_沒有區段_正體中文環境_回傳無資料文字() {
        // Given
        let segments: [BLDonutSegment] = []

        // When
        let summary = BLDonutChart.ChartAccessibilityDescriptor.summary(
            for: segments,
            locale: AppLanguage.traditionalChinese.locale
        )

        // Then
        #expect(summary == "圈狀圖，目前沒有資料")
    }
}
