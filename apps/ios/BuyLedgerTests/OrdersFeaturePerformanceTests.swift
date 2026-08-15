//
//  OrdersFeaturePerformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import XCTest
@testable import BuyLedger

/// 衡量 filteredOrders 的大量資料效能
final class OrdersFeaturePerformanceTests: XCTestCase {
    
    // MARK: - Tests
    
    /// 1,000 筆訂單下，搜尋字串為空 (最寬鬆的 filter 路徑) 的執行成本
    func testFilteredOrdersBaselineWithThousandOrders() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)
        
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar)
            }
        }
        
        Self.assertNoRegression(elapsed, label: "testFilteredOrdersBaselineWithThousandOrders")
    }
    
    /// 1,000 筆訂單下，搜尋字串會命中部分項目時的執行成本
    func testFilteredOrdersWithSearchHittingHalf() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)
        state.searchText = "even"
        
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar)
            }
        }
        
        Self.assertNoRegression(elapsed, label: "testFilteredOrdersWithSearchHittingHalf")
    }
    
    /// 1,000 筆訂單下同時套用狀態 + 日期區間 + 搜尋字串
    func testFilteredOrdersWithAllFiltersActive() {
        var state = OrdersFeature.State()
        state.orders = Self.makeOrders(count: 1_000)
        state.searchText = "evenly numbered"
        state.selectedStatus = .status(.delivered)
        state.selectedDatePeriod = .thisMonth
        
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar)
            }
        }
        
        Self.assertNoRegression(elapsed, label: "testFilteredOrdersWithAllFiltersActive")
    }
    
    /// 量測大量訂單與開團狀態篩選的成本
    func testFilteredOrdersWithCampaignStatusFilterAndDozensOfCampaigns() {
        var state = OrdersFeature.State()
        let campaigns = Self.makeCampaigns(count: 40)
        state.campaigns = campaigns
        state.orders = Self.makeOrders(count: 1_000, campaigns: campaigns)
        state.selectedCampaignStatus = .ongoing
        
        let elapsed = Self.clock.measure {
            for _ in 0..<20 {
                _ = state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar)
            }
        }
        
        Self.assertNoRegression(
            elapsed,
            threshold: Self.campaignStatusFilterRegressionThreshold,
            label: "testFilteredOrdersWithCampaignStatusFilterAndDozensOfCampaigns"
        )
    }
    
    /// 1,000 筆訂單下的總覽彙總基準
    func testDashboardStatsRevenueAttributionBaselineWithThousandOrders() {
        let orders = Self.makeOrders(count: 1_000)
        
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
        
        Self.assertNoRegression(
            elapsed, label: "testDashboardStatsRevenueAttributionBaselineWithThousandOrders")
    }
}

// MARK: - Static Properties

private extension OrdersFeaturePerformanceTests {
    
    /// 計時用的單調時鐘 (不受牆鐘調整影響)
    static let clock = ContinuousClock()
    
    /// 共用效能退化門檻
    static let regressionThreshold = Duration.seconds(3)
    
    /// 開團狀態篩選的效能門檻
    static let campaignStatusFilterRegressionThreshold = Duration.seconds(0.06)
}

// MARK: - Private Method

private extension OrdersFeaturePerformanceTests {
    
    /// 斷言單次計時結果未超出退化門檻
    static func assertNoRegression(
        _ elapsed: Duration,
        threshold: Duration = regressionThreshold,
        label: String
    ) {
        XCTAssertLessThan(
            elapsed,
            threshold,
            "\(label) 花費 \(elapsed)，超出退化門檻 \(threshold)"
        )
    }
    
    /// 產生指定數量的虛擬訂單，狀態與類別輪流分配以避免分支單一化
    /// - Parameters:
    ///   - count: 要產生的訂單數量
    ///   - campaigns: 可供訂單輪流歸屬的開團清單
    /// - Returns: 產生的測試訂單清單
    static func makeOrders(count: Int, campaigns: [Campaign]? = nil) -> [LedgerOrder] {
        let statuses: [OrderStatus] = [
            .quoting, .confirmed, .purchased, .shipping, .delivered, .cancelled,
        ]
        let categories = ["美妝", "服飾", "精品", "evenly numbered", "其他"]
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        
        return (0..<count).map { index in
            let status = statuses[index % statuses.count]
            let category = categories[index % categories.count]
            let isEven = index.isMultiple(of: 2)
            let campaignNames = campaigns.map { [$0[index % $0.count].name] } ?? []
            
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
                        name: "perf item \(index)", quantity: 1, unitPrice: Decimal(100 + index))
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
                campaignNames: campaignNames,
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [],
                mergedSourceIDs: []
            )
        }
    }
    
    /// 產生指定數量的虛擬開團，狀態輪流分配 (進行中／已收單)
    /// - Parameter count: 要產生的開團數量
    /// - Returns: 產生的測試開團清單
    static func makeCampaigns(count: Int) -> [Campaign] {
        (0..<count).map { index in
            Campaign(
                id: "CAMPAIGN-PERF-\(index)",
                name: "perf campaign \(index)",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: index.isMultiple(of: 2) ? .ongoing : .closed,
                settledDate: nil,
                notes: ""
            )
        }
    }
}
