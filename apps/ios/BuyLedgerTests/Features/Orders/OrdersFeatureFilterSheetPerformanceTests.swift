//
//  OrdersFeatureFilterSheetPerformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import XCTest

@testable import BuyLedger

/// `OrderFilterFeature` 的效能測試，以 `ContinuousClock` 計時並斷言耗時上限，涵蓋篩選面板的類別分組
final class OrdersFeatureFilterSheetPerformanceTests: XCTestCase {

    /// 驗證千筆訂單下，篩選面板的類別分組在空白與「類別」兩種搜尋詞各計算 20 次時，總耗時未超過退化門檻，且顯示與已選數量的加總符合預期，避免空殼結果通過
    ///
    /// - Note: 2026-10-18 iPhone 17 模擬器整條測試含夾具實測 0.092 秒，
    ///   共計算 40 次，退化門檻取約 6 倍 (550 ms)
    func testFilterSheetCategoryGroups_小規模千筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = OrdersFeaturePerformanceTestSupport.makeCategoryGroupsFixture(
            orderCount: 1_000,
            categoryCount: 50,
            campaignCount: 20
        )
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: fixture.orders),
            campaigns: SharedReader(value: fixture.campaigns),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: fixture.categories)),
            committedFilterSelection: OrderFilterSelection(categories: fixture.selected),
            dateContext: fixture.context
        )
        state.categoryGroupExpansion.expandedKinds = [.ongoing, .closed]
        let clock = ContinuousClock()
        var totalDisplayedCount = 0
        var totalSelectedCount = 0

        // When
        let elapsed = clock.measure {
            for query in ["", "類別"] {
                state.filterSheetSearchText = query
                for _ in 0..<20 {
                    let groups = state.filterSheetCategoryGroups
                    totalDisplayedCount += groups.reduce(0) { count, group in
                        count + group.displayedCount
                    }
                    totalSelectedCount += groups.reduce(0) { count, group in
                        count + group.selectedCount
                    }
                }
            }
        }

        // Then
        XCTAssertEqual(totalDisplayedCount, 2_000)
        XCTAssertEqual(totalSelectedCount, 200)
        XCTAssertLessThan(elapsed, Duration.milliseconds(550))
    }

    /// 驗證一萬筆訂單下，篩選面板的類別分組在空白與「類別」兩種搜尋詞各計算 20 次時，總耗時未超過退化門檻，且顯示與已選數量的加總符合預期，避免空殼結果通過
    ///
    /// - Note: 2026-10-18 iPhone 17 模擬器整條測試含夾具實測 0.957 秒，
    ///   共計算 40 次，退化門檻取約 6 倍 (5,700 ms)
    func testFilterSheetCategoryGroups_大規模萬筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = OrdersFeaturePerformanceTestSupport.makeCategoryGroupsFixture(
            orderCount: 10_000,
            categoryCount: 500,
            campaignCount: 200
        )
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: fixture.orders),
            campaigns: SharedReader(value: fixture.campaigns),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: fixture.categories)),
            committedFilterSelection: OrderFilterSelection(categories: fixture.selected),
            dateContext: fixture.context
        )
        state.categoryGroupExpansion.expandedKinds = [.ongoing, .closed]
        let clock = ContinuousClock()
        var totalDisplayedCount = 0
        var totalSelectedCount = 0

        // When
        let elapsed = clock.measure {
            for query in ["", "類別"] {
                state.filterSheetSearchText = query
                for _ in 0..<20 {
                    let groups = state.filterSheetCategoryGroups
                    totalDisplayedCount += groups.reduce(0) { count, group in
                        count + group.displayedCount
                    }
                    totalSelectedCount += groups.reduce(0) { count, group in
                        count + group.selectedCount
                    }
                }
            }
        }

        // Then
        XCTAssertEqual(totalDisplayedCount, 20_000)
        XCTAssertEqual(totalSelectedCount, 200)
        XCTAssertLessThan(elapsed, Duration.milliseconds(5_700))
    }
}
