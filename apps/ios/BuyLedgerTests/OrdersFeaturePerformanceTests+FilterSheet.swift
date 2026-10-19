//
//  OrdersFeaturePerformanceTests+FilterSheet.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import XCTest

@testable import BuyLedger

extension OrdersFeaturePerformanceTests {

    /// 1,000 筆訂單下完整分組屬性涵蓋搜尋與非搜尋，且空殼不得通過
    ///
    /// - Note: 2026-10-18 iPhone 17 模擬器整條測試含夾具實測 0.092 秒，
    ///   共計算 40 次，退化門檻取約 6 倍 (550 ms)
    func testFilterSheetCategoryGroups_小規模千筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = Self.makeCategoryGroupsFixture(
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

    /// 10,000 筆訂單下完整分組屬性涵蓋搜尋與非搜尋，且空殼不得通過
    ///
    /// - Note: 2026-10-18 iPhone 17 模擬器整條測試含夾具實測 0.957 秒，
    ///   共計算 40 次，退化門檻取約 6 倍 (5,700 ms)
    func testFilterSheetCategoryGroups_大規模萬筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = Self.makeCategoryGroupsFixture(
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

// MARK: - Nested Types

extension OrdersFeaturePerformanceTests {

    /// 類別分組效能測試的夾具資料
    struct CategoryGroupsFixture {

        /// 類別名稱
        let categories: [String]

        /// 訂單資料
        let orders: [LedgerOrder]

        /// 開團資料
        let campaigns: [Campaign]

        /// 日期上下文
        let context: OrderDateContext

        /// 分組結果
        let groups: [OrderCategoryGroups.Group]

        /// 已選取的類別
        let selected: Set<String>
    }
}

// MARK: - Internal Method

extension OrdersFeaturePerformanceTests {

    /// 產生確定性的類別、訂單與開團效能測試夾具資料
    ///
    /// - Parameters:
    ///   - orderCount: 訂單數量
    ///   - categoryCount: 類別數量
    ///   - campaignCount: 開團數量
    /// - Returns: 組裝好的效能測試夾具
    static func makeCategoryGroupsFixture(
        orderCount: Int,
        categoryCount: Int,
        campaignCount: Int
    ) -> CategoryGroupsFixture {
        let categories = (0..<categoryCount).map { "類別-\($0)" }
        let campaigns = (0..<campaignCount).map {
            Campaign.fixture(
                id: "PERF-C-\($0)",
                name: "開團-\($0)",
                status: $0.isMultiple(of: 2) ? .ongoing : .closed
            )
        }
        let orders = (0..<orderCount).map { index in
            let catCount = (index % 3) + 1
            let orderCategories = (0..<catCount).map {
                categories[(index * 3 + $0) % categories.count]
            }
            let campCount = index % 3
            let orderCampaigns = (0..<campCount).map {
                campaigns[(index * 2 + $0) % campaigns.count].name
            }
            return LedgerOrder.fixture(
                id: "BL-PERF-\(index)",
                categories: orderCategories,
                campaignNames: orderCampaigns
            )
        }
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let selected = Set(categories.prefix(5))
        let groups = OrderCategoryGroups.groups(
            categories: categories,
            orders: orders,
            campaigns: campaigns,
            context: context
        )

        return CategoryGroupsFixture(
            categories: categories,
            orders: orders,
            campaigns: campaigns,
            context: context,
            groups: groups,
            selected: selected
        )
    }
}
