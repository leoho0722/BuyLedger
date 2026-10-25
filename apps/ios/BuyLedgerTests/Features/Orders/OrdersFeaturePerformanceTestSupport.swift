//
//  OrdersFeaturePerformanceTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

@testable import BuyLedger

/// 提供訂單與篩選面板效能測試共用的固定分組資料
enum OrdersFeaturePerformanceTestSupport {}

// MARK: - Nested Types

extension OrdersFeaturePerformanceTestSupport {

    /// 類別分組效能測試的夾具資料
    struct CategoryGroupsFixture {

        /// 全部類別的名稱
        let categories: [String]

        /// 產生的測試訂單清單
        let orders: [LedgerOrder]

        /// 產生的測試開團清單
        let campaigns: [Campaign]

        /// 分組時使用的日期上下文
        let context: OrderDateContext

        /// 預先算好的類別分組，供計算初始展開狀態使用
        let groups: [OrderCategoryGroups.Group]

        /// 預設選取的前 5 個類別名稱
        let selected: Set<String>
    }
}

// MARK: - Internal Method

extension OrdersFeaturePerformanceTestSupport {

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
