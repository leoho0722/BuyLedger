//
//  InsightsHeatmapTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `InsightsHeatmap` 的單元測試，涵蓋格子座標與最高筆數
struct InsightsHeatmapTests {

    /// 驗證 `make` 把今天的訂單放入最後一週的格子，星期索引為 3 (週四)
    @Test
    func make_今天的訂單_落在最後一週與對應星期() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .quoting,
                date: TestDependencies.fixedNow,
                charged: 1
            ),
        ]

        // When
        let heatmap = InsightsHeatmap.make(
            orders: orders,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(heatmap.cells[InsightsHeatmap.Key(week: 7, weekday: 3)] == 1)
        #expect(heatmap.cells.values.reduce(0, +) == 1)
        #expect(heatmap.maxCount == 1)
    }

    /// 驗證 `make` 把同一天多筆訂單的筆數加總在同一格，`maxCount` 取該格的數值
    @Test
    func make_同一天多筆訂單_最高筆數為該日筆數() {
        // Given
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .quoting,
                date: TestDependencies.fixedNow,
                charged: 1
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "B",
                status: .quoting,
                date: TestDependencies.fixedNow,
                charged: 1
            ),
        ]

        // When
        let heatmap = InsightsHeatmap.make(
            orders: orders,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(heatmap.cells[InsightsHeatmap.Key(week: 7, weekday: 3)] == 2)
        #expect(heatmap.maxCount == 2)
    }

    /// 驗證超出顯示週數的訂單不計入 `cells`，沒有資料時 `maxCount` 為 1
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func make_超出顯示週數的訂單_不計入() throws {
        // Given
        let oldDate = try #require(
            TestDependencies.fixedCalendar.date(
                byAdding: .day,
                value: -100,
                to: TestDependencies.fixedNow
            )
        )
        let orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .quoting,
                date: oldDate,
                charged: 1
            ),
        ]

        // When
        let heatmap = InsightsHeatmap.make(
            orders: orders,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(heatmap.cells.isEmpty)
        #expect(heatmap.maxCount == 1)
    }
}
