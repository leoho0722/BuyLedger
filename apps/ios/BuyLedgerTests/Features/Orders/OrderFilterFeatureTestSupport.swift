//
//  OrderFilterFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

@testable import BuyLedger

/// 提供訂單篩選測試共用的狀態與類別分組資料
enum OrderFilterFeatureTestSupport {}

// MARK: - Internal Method

extension OrderFilterFeatureTestSupport {

    /// 建立沒有訂單的篩選面板初始狀態，可指定可用類別與已套用的篩選
    ///
    /// - Parameters:
    ///   - categories: 可用的主檔類別，預設為空
    ///   - committedFilterSelection: 已套用篩選，預設為全部
    /// - Returns: 不存取持久化主檔的測試初始值
    static func makeState(
        categories: [String] = [],
        committedFilterSelection: OrderFilterSelection = OrderFilterSelection()
    ) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: categories)),
            committedFilterSelection: committedFilterSelection,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 沿用清單的共用引用建立篩選面板的初始狀態，供呈現與提交測試直接使用
    ///
    /// - Parameter state: 清單的共用資料與已套用篩選
    /// - Returns: 暫存值與已套用值一致的篩選狀態
    static func makeState(for state: OrderListFeature.State) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: state.$orders,
            campaigns: state.$campaigns,
            lookupCatalog: state.$lookupCatalog,
            committedFilterSelection: state.committedFilterSelection,
            dateContext: state.dateContext
                ?? OrderDateContext(
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
        )
    }

    /// 建立含主檔與訂單類別的篩選狀態，預設開團資料會分為開團中與已收單各三類
    ///
    /// - Parameters:
    ///   - selection: 開啟面板時已套用的篩選
    ///   - campaigns: 可選的共用開團引用，省略時使用兩個固定開團
    /// - Returns: 依指定開團與已套用篩選建立的面板狀態
    static func makeGroupedState(
        selection: OrderFilterSelection = OrderFilterSelection(),
        campaigns: SharedReader<[Campaign]>? = nil
    ) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: SharedReader(value: [
                LedgerOrder.fixture(
                    id: "ongoing",
                    categories: ["美妝", "3C", "零食"],
                    campaignNames: ["春季團"]
                ),
                LedgerOrder.fixture(id: "closed", categories: ["精品", "食品"], campaignNames: ["冬季團"]),
            ]),
            campaigns: campaigns
                ?? SharedReader(value: [
                    Campaign.fixture(
                        id: "spring",
                        name: "春季團",
                        closeDate: TestDependencies.fixedNow
                    ),
                    Campaign.fixture(id: "winter", name: "冬季團", status: .closed),
                ]),
            lookupCatalog: SharedReader(
                value: LookupCatalog(categories: ["美妝", "零食", "精品", "食品", "書籍"])
            ),
            committedFilterSelection: selection,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }
}
