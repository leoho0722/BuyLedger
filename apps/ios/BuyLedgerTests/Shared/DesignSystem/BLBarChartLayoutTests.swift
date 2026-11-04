//
//  BLBarChartLayoutTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/2.
//

import Foundation
import Testing

@testable import BuyLedger

/// `BLBarChart.Layout.stridedLabels` 的 X 軸標籤抽樣測試
struct BLBarChartLayoutTests {

    /// 驗證標準間距下，十二筆資料依寬度抽稀為六個標籤，並保留最後一筆作為右端錨點
    @Test
    func stridedLabels_標準間距_依寬度抽稀並保留最後一筆() {
        // Given
        let data = Self.monthlyData()

        // When
        let labels = BLBarChart.Layout.stridedLabels(
            data: data,
            renderWidth: 330,
            minLabelSpacing: 28
        )

        // Then
        #expect(labels == ["1 月", "3 月", "5 月", "7 月", "9 月", "12 月"])
    }

    /// 驗證無障礙字級放大後的間距下，抽樣間隔加大為每三筆一個標籤
    @Test
    func stridedLabels_無障礙放大間距_加大抽樣間隔() {
        // Given
        let data = Self.monthlyData()

        // When
        let labels = BLBarChart.Layout.stridedLabels(
            data: data,
            renderWidth: 330,
            minLabelSpacing: 76
        )

        // Then
        #expect(labels == ["1 月", "4 月", "7 月", "12 月"])
    }

    /// 驗證沒有資料時回傳空陣列
    @Test
    func stridedLabels_空資料_回傳空陣列() {
        // Given
        let data: [BLBarChartValue] = []

        // When
        let labels = BLBarChart.Layout.stridedLabels(
            data: data,
            renderWidth: 330,
            minLabelSpacing: 28
        )

        // Then
        #expect(labels == [])
    }

    /// 驗證只有一筆資料時保留該筆標籤
    @Test
    func stridedLabels_單筆資料_只保留該筆() {
        // Given
        let data = [Self.monthlyData()[0]]

        // When
        let labels = BLBarChart.Layout.stridedLabels(
            data: data,
            renderWidth: 330,
            minLabelSpacing: 76
        )

        // Then
        #expect(labels == ["1 月"])
    }

    /// 驗證容量不足兩個標籤時，只保留首尾兩筆，避免丟失起點
    @Test
    func stridedLabels_容量不足兩個_只保留首尾() {
        // Given
        let data = Self.monthlyData()

        // When
        let labels = BLBarChart.Layout.stridedLabels(
            data: data,
            renderWidth: 150,
            minLabelSpacing: 101
        )

        // Then
        #expect(labels == ["1 月", "12 月"])
    }
}

// MARK: - Private Method

private extension BLBarChartLayoutTests {

    /// 產生十二個月的長條圖資料，標籤依序為「1 月」至「12 月」
    ///
    /// - Returns: 十二筆長條圖資料，數值由 1 遞增至 12
    static func monthlyData() -> [BLBarChartValue] {
        (1...12).map {
            BLBarChartValue(label: "\($0) 月", value: Double($0), valueDescription: "NT$\($0)")
        }
    }
}
