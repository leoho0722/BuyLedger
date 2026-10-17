//
//  RootNavigationOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 以根功能解析後的日期與行事曆處理跨功能導覽與日期刷新
struct RootNavigationOperations {

    // MARK: - Properties

    /// 套用訂單日期篩選時的參考時間
    let referenceDate: Date

    /// 套用訂單日期篩選時的行事曆
    let calendar: Calendar
}

// MARK: - Internal Method

extension RootNavigationOperations {

    /// 以注入的現在時間與行事曆重寫開團、訂單、總覽與分析的日期脈絡
    ///
    /// - Parameter state: 目前的根層狀態，直接就地修改
    func refreshDateContexts(state: inout RootFeature.State) {
        let context = CampaignDateContext(now: referenceDate, calendar: calendar)
        state.campaigns.refreshDateContext(context)
        state.orders.refreshDateContext(now: context.now, calendar: context.calendar)
        state.dashboard.refreshDateContext(now: context.now, calendar: context.calendar)
        state.insights.refreshDateContext(now: context.now, calendar: context.calendar)
    }

    /// 切到開團頁並經單一入口推入指定開團的詳情
    ///
    /// - Parameters:
    ///   - name: 既有開團名稱
    ///   - state: 要就地更新的根狀態
    func showCampaign(named name: String, state: inout RootFeature.State) {
        state.selectedTab = .campaigns
        guard let id = state.campaigns.campaigns.first(where: { $0.name == name })?.id else {
            return
        }
        state.campaigns.showDetail(campaignID: id)
    }

    /// 切到訂單頁並只套用指定類別，清除原有狀態、日期與搜尋條件
    ///
    /// - Parameters:
    ///   - category: 要精準比對的商品類別
    ///   - state: 要就地更新的根狀態
    func showOrders(category: String, state: inout RootFeature.State) {
        // 類別深連結使用精準 `category` 篩選，避免 `searchText` 誤中
        state.selectedTab = .orders
        state.orders.applyFilterNavigation(
            searchText: "",
            category: category,
            now: referenceDate,
            calendar: calendar
        )
    }

    /// 切到訂單頁並以客戶名稱搜尋，清除原有狀態、日期與類別篩選
    ///
    /// - Parameters:
    ///   - customer: 要搜尋的客戶名稱
    ///   - state: 要就地更新的根狀態
    func showOrders(customer: String, state: inout RootFeature.State) {
        state.selectedTab = .orders
        state.orders.applyFilterNavigation(
            searchText: customer,
            category: nil,
            now: referenceDate,
            calendar: calendar
        )
    }
}
