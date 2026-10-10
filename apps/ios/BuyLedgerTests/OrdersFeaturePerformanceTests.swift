//
//  OrdersFeaturePerformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import XCTest

@testable import BuyLedger

/// 衡量訂單清單的 `filteredOrders` 與總覽統計 `DashboardStats` 在大量訂單下的執行耗時是否退化
final class OrdersFeaturePerformanceTests: XCTestCase {

    // MARK: - Properties

    /// 計時用的時鐘，不受系統時間調整影響
    private static let clock = ContinuousClock()

    /// 超過此耗時即判定為效能退化
    private static let regressionThreshold = Duration.seconds(3)

    /// 1,000 筆訂單、搜尋文字為空 (篩選條件最少) 時的執行成本
    func testFilteredOrders_千筆訂單無搜尋文字_耗時未超過退化門檻() {
        // Given
        let state = OrderListFeatureTests.makeState(orders: Self.makeOrders(count: 1_000))

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testFilteredOrders_千筆訂單無搜尋文字_耗時未超過退化門檻")
    }

    /// 1,000 筆訂單、搜尋文字命中部分訂單時的執行成本
    func testFilteredOrders_千筆訂單搜尋命中半數_耗時未超過退化門檻() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: Self.makeOrders(count: 1_000))
        state.searchText = "even"

        // When
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders
            }
        }

        // Then
        Self.assertNoRegression(elapsed, label: "testFilteredOrders_千筆訂單搜尋命中半數_耗時未超過退化門檻")
    }

    /// 1,000 筆訂單同時套用狀態、日期區間與搜尋文字時的執行成本
    func testFilteredOrders_千筆訂單全部篩選同時套用_耗時未超過退化門檻() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: Self.makeOrders(count: 1_000))
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

    /// 1,000 筆訂單下的總覽統計耗時基準
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
