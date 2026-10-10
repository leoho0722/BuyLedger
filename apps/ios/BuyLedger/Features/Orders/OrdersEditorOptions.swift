//
//  OrdersEditorOptions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 以訂單與主檔快照建立所有表單入口共用的選項
enum OrdersEditorOptions {

}

// MARK: - Internal Method

extension OrdersEditorOptions {

    /// 依現有資料與呼叫端時間建立表單選項，不寫入開團投影
    ///
    /// - Parameters:
    ///   - state: 容器的唯讀快照
    ///   - now: 評估開團結單日的現在時間
    ///   - calendar: 結單日判斷與完整時間格式化使用的行事曆
    /// - Returns: 可選主檔、進行中開團、幣別與行事曆
    static func make(
        state: OrdersFeature.State,
        now: Date,
        calendar: Calendar
    ) -> OrderEditOptions {
        let campaignNames = state.campaigns
            .map { $0.evaluatingAutoClose(asOf: now, calendar: calendar) }
            .filter { $0.status == .ongoing }
            .map(\.name)
        return OrderEditOptions(
            orderSources: orderSources(orders: state.orders, catalog: state.lookupCatalog),
            categories: state.list.availableCategories,
            paymentMethods: state.list.availablePaymentMethods,
            reconciliationStatuses: reconciliationStatuses(
                orders: state.orders,
                catalog: state.lookupCatalog
            ),
            campaigns: campaignNames,
            currencyCodes: state.currencyCodes.isEmpty
                ? CurrencyCode.defaults : state.currencyCodes,
            calendar: calendar
        )
    }

    /// 合併主檔與訂單已使用的來源名稱
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 四種主檔目錄
    /// - Returns: 去重後依語言排序的訂單來源
    static func orderSources(orders: [LedgerOrder], catalog: LookupCatalog) -> [String] {
        names(master: catalog.orderSources, used: orders.map(\.orderSource))
    }

    /// 合併主檔與訂單已使用的對帳狀態
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 四種主檔目錄
    /// - Returns: 去重後依語言排序的對帳狀態
    static func reconciliationStatuses(orders: [LedgerOrder], catalog: LookupCatalog) -> [String] {
        names(master: catalog.reconciliationStatuses, used: orders.map(\.reconciliationStatus))
    }
}

// MARK: - Private Method

private extension OrdersEditorOptions {

    /// 保留主檔名稱並合併訂單中非空的使用值
    ///
    /// - Parameters:
    ///   - master: 主檔名稱
    ///   - used: 訂單已使用的名稱
    /// - Returns: 去重後依語言排序的名稱
    static func names(master: [String], used: [String]) -> [String] {
        let normalized = used
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var merged = Set(master)
        merged.formUnion(normalized)
        return merged.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }
}
