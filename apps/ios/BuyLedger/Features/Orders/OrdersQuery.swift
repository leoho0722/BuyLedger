//
//  OrdersQuery.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

/// 訂單列表共用的純篩選計算，不接收功能狀態
enum OrdersQuery {

}

// MARK: - Internal Method

extension OrdersQuery {

    /// 依所有已選取條件篩選訂單，保留輸入順序
    ///
    /// - Parameters:
    ///   - orders: 要篩選的訂單
    ///   - selectedStatus: 訂單狀態條件
    ///   - selectedDatePeriod: 相對日期區間條件
    ///   - selectedCategory: 商品類別條件
    ///   - selectedPaymentMethod: 付款方式條件
    ///   - searchText: 訂單與品項搜尋文字
    ///   - now: 相對日期區間的基準時間
    ///   - calendar: 日期區間使用的行事曆
    /// - Returns: 符合所有條件的訂單
    static func filteredOrders(
        orders: [LedgerOrder],
        selectedStatus: OrderStatusFilter,
        selectedDatePeriod: OrderDatePeriod,
        selectedCategory: String?,
        selectedPaymentMethod: String?,
        searchText: String,
        now: Date,
        calendar: Calendar
    ) -> [LedgerOrder] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return orders.filter { order in
            let isStatusMatch = selectedStatus.orderStatus.map {
                $0 == order.status
            } ?? true
            guard isStatusMatch else {
                return false
            }
            guard selectedDatePeriod.includes(
                order.date,
                referenceDate: now,
                calendar: calendar
            ) else {
                return false
            }
            let isCategoryMatch = selectedCategory.map {
                order.categories.contains($0)
            } ?? true
            guard isCategoryMatch else {
                return false
            }
            let isPaymentMethodMatch = selectedPaymentMethod.map {
                $0 == order.paymentMethod
            } ?? true
            guard isPaymentMethodMatch else {
                return false
            }
            return normalizedQuery.isEmpty || order.searchableText.contains(normalizedQuery)
        }
    }
}
