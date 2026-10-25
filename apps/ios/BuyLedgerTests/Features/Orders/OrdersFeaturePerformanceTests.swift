//
//  OrdersFeaturePerformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import XCTest

@testable import BuyLedger

/// 訂單清單篩選、總覽統計與類別分組的效能測試，以 `ContinuousClock` 計時，耗時超過退化門檻即失敗
final class OrdersFeaturePerformanceTests: XCTestCase {

    // MARK: - Properties

    /// 計時用的時鐘，不受系統時間調整影響
    private static let clock = ContinuousClock()

    /// 判定效能退化的耗時上限
    private static let regressionThreshold = Duration.seconds(3)

    /// 類別分組小規模退化門檻 (2026-10-18 iPhone 17 實測 0.018 秒，取約 6 倍)
    private static let categoryGroupsSmallScaleThreshold = Duration.milliseconds(110)

    /// 類別分組大規模退化門檻 (2026-10-18 iPhone 17 實測 0.182 秒，取約 6 倍)
    private static let categoryGroupsLargeScaleThreshold = Duration.milliseconds(1_100)

    /// 驗證 1,000 筆訂單、搜尋文字為空 (篩選條件最少) 時，連續 20 次取 `filteredOrders` 的耗時未超過退化門檻
    func testFilteredOrders_千筆訂單無搜尋文字_耗時未超過退化門檻() {
        // Given
        let state = OrderListFeatureTestSupport.makeState(orders: Self.makeOrders(count: 1_000))

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testFilteredOrders_千筆訂單無搜尋文字_耗時未超過退化門檻")
    }

    /// 驗證 1,000 筆訂單搜尋「even」命中 600 筆時，連續 20 次篩選的耗時未超過退化門檻
    ///
    /// - Note: 命中內容是偶數客戶 500 筆與類別「evenly numbered」200 筆的聯集
    func testFilteredOrders_千筆訂單搜尋命中六百筆_耗時未超過退化門檻() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: Self.makeOrders(count: 1_000))
        state.searchText = "even"

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testFilteredOrders_千筆訂單搜尋命中六百筆_耗時未超過退化門檻")
    }

    /// 驗證 1,000 筆訂單同時套用搜尋、狀態與日期條件時，連續 20 次篩選的耗時未超過退化門檻
    ///
    /// - Note: 條件為搜尋「evenly numbered」、狀態 `delivered` 與日期區間 `thisMonth`
    func testFilteredOrders_千筆訂單全部篩選同時套用_耗時未超過退化門檻() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: Self.makeOrders(count: 1_000))
        state.searchText = "evenly numbered"
        state.selectedStatus = .status(.delivered)
        state.selectedDatePeriod = .thisMonth

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testFilteredOrders_千筆訂單全部篩選同時套用_耗時未超過退化門檻")
    }

    /// 驗證 1,000 筆訂單的總覽統計，連續 20 次建立 `DashboardStats` 的耗時未超過退化門檻
    func testDashboardStats_千筆訂單_耗時未超過退化門檻() {
        // Given
        let orders = Self.makeOrders(count: 1_000)

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = DashboardStats(
                    orders: orders,
                    monthlyGoal: 10_000,
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testDashboardStats_千筆訂單_耗時未超過退化門檻")
    }

    /// 驗證 1,000 筆訂單、50 類別、20 開團的類別分組，連續 20 輪分組後分別以空搜尋文字與「類別」顯示，耗時未超過小規模退化門檻
    func testCategoryGroups_小規模千筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = OrdersFeaturePerformanceTestSupport.makeCategoryGroupsFixture(
            orderCount: 1_000,
            categoryCount: 50,
            campaignCount: 20
        )
        let expansion = OrderCategoryGroups.initialExpansion(
            groups: fixture.groups,
            selected: fixture.selected
        )

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                let groups = OrderCategoryGroups.groups(
                    categories: fixture.categories,
                    orders: fixture.orders,
                    campaigns: fixture.campaigns,
                    context: fixture.context
                )
                for query in ["", "類別"] {
                    _ = OrderCategoryGroups.displayGroups(
                        groups: groups,
                        expansion: expansion,
                        selected: fixture.selected,
                        searchText: query
                    )
                }
            }
        }

        // Then
        Self.assertNoRegression(
            elapsed,
            threshold: Self.categoryGroupsSmallScaleThreshold,
            label: "testCategoryGroups_小規模千筆訂單_耗時未超過退化門檻"
        )
    }

    /// 驗證 10,000 筆訂單、500 類別、200 開團的類別分組，連續 20 輪分組後分別以空搜尋文字與「類別」顯示，耗時未超過大規模退化門檻
    func testCategoryGroups_大規模萬筆訂單_耗時未超過退化門檻() {
        // Given
        let fixture = OrdersFeaturePerformanceTestSupport.makeCategoryGroupsFixture(
            orderCount: 10_000,
            categoryCount: 500,
            campaignCount: 200
        )
        let expansion = OrderCategoryGroups.initialExpansion(
            groups: fixture.groups,
            selected: fixture.selected
        )

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                let groups = OrderCategoryGroups.groups(
                    categories: fixture.categories,
                    orders: fixture.orders,
                    campaigns: fixture.campaigns,
                    context: fixture.context
                )
                for query in ["", "類別"] {
                    _ = OrderCategoryGroups.displayGroups(
                        groups: groups,
                        expansion: expansion,
                        selected: fixture.selected,
                        searchText: query
                    )
                }
            }
        }

        // Then
        Self.assertNoRegression(
            elapsed,
            threshold: Self.categoryGroupsLargeScaleThreshold,
            label: "testCategoryGroups_大規模萬筆訂單_耗時未超過退化門檻"
        )
    }
}

// MARK: - Private Method

private extension OrdersFeaturePerformanceTests {

    /// 產生指定數量的虛擬訂單，狀態與類別輪流分配，避免所有訂單走同一條判斷路徑
    ///
    /// - Parameter count: 要產生的訂單數量
    /// - Returns: 產生的測試訂單清單
    static func makeOrders(count: Int) -> [LedgerOrder] {
        let statuses: [OrderStatus] = [
            .quoting,
            .confirmed,
            .purchased,
            .shipping,
            .delivered,
            .cancelled,
        ]
        let categories = ["美妝", "服飾", "精品", "evenly numbered", "其他"]
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

        return (0..<count).map { index in
            let status = statuses[index % statuses.count]
            let category = categories[index % categories.count]
            let isEven = index.isMultiple(of: 2)

            return LedgerOrder(
                id: "BL-PERF-\(index)",
                customer: LedgerCustomer(
                    name: isEven ? "even customer \(index)" : "odd customer \(index)",
                    initials: isEven ? "EV" : "OD",
                    tier: .regular
                ),
                status: status,
                currency: .twd,
                date: baseDate.addingTimeInterval(Double(index) * 3_600),
                items: [
                    LedgerOrderItem(
                        name: "perf item \(index)",
                        quantity: 1,
                        unitPrice: Decimal(100 + index)
                    ),
                ],
                itemCost: Decimal(100 + index),
                domesticShipping: 0,
                internationalShipping: 50,
                foreignDomesticShipping: 0,
                cardFeeRate: Decimal(string: "0.015") ?? 0,
                platformFeeRate: 0,
                paymentFeeRate: 0,
                chargedAmount: Decimal(200 + index),
                cardlessDeductionAmount: 0,
                cardlessSupplementAmount: 0,
                orderSource: "蝦皮",
                categories: [category],
                paymentMethod: "",
                notes: "",
                reconciliationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
        }
    }

    /// 斷言單次計時結果未超出退化門檻
    ///
    /// - Parameters:
    ///   - elapsed: 單次計時的結果
    ///   - threshold: 允許的最長耗時
    ///   - label: 超出門檻時訊息中標示的測試名稱
    static func assertNoRegression(
        _ elapsed: Duration,
        threshold: Duration = regressionThreshold,
        label: String
    ) {
        XCTAssertLessThan(elapsed, threshold, "\(label) 花費 \(elapsed)，超出退化門檻 \(threshold)")
    }
}
