//
//  OrdersFeaturePerformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import XCTest
@testable import BuyLedger

/// 衡量 ``OrdersFeature/State/filteredOrders(referenceDate:calendar:)`` 在大量訂單下的執行成本
///
/// 採 XCTest 的 `measure { }` (Swift Testing 目前未內建 perf measurement)，對應到 Xcode 的 baseline tracking
final class OrdersFeaturePerformanceTests: XCTestCase {

    // MARK: - Tests

    /// 1,000 筆訂單下，搜尋字串為空 (最寬鬆的 filter 路徑) 的執行成本
    func testFilteredOrdersBaselineWithThousandOrders() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)

        measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            }
        }
    }

    /// 1,000 筆訂單下，搜尋字串會命中部分項目時的執行成本
    func testFilteredOrdersWithSearchHittingHalf() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)
        state.searchText = "even"

        measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            }
        }
    }

    /// 1,000 筆訂單下同時套用狀態 + 日期區間 + 搜尋字串
    func testFilteredOrdersWithAllFiltersActive() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)
        state.searchText = "evenly numbered"
        state.selectedStatus = .status(.delivered)
        state.selectedDatePeriod = .thisMonth

        measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            }
        }
    }
}

// MARK: - Helpers

private extension OrdersFeaturePerformanceTests {

    /// 產生指定數量的虛擬訂單，狀態與類別輪流分配以避免分支單一化
    /// - Parameter count: 要產生的訂單數量
    /// - Returns: 訂單陣列
    static func makeOrders(count: Int) -> [LedgerOrder] {
        let statuses: [OrderStatus] = [.quoting, .confirmed, .purchased, .shipping, .delivered, .cancelled]
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
                    LedgerOrderItem(name: "perf item \(index)", quantity: 1, unitPrice: Decimal(100 + index)),
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
                verificationStatus: "",
                campaignNames: [],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
        }
    }
}
