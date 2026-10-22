//
//  CustomerRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation

/// 客戶名單畫面顯示用的彙總列
struct CustomerRow: Equatable, Sendable {

    // MARK: - Properties

    /// 客戶姓名
    let name: String

    /// 顯示在頭像上的姓名縮寫
    let initials: String

    /// 客戶分級
    let tier: CustomerTier

    /// 依營收歸屬口徑計入的訂單筆數
    let orderCount: Int

    /// 累計消費 (NT$)
    let totalSpent: Decimal

    /// 最近一筆訂單的日期
    let lastOrderDate: Date
}

// MARK: - Internal Method

extension CustomerRow {

    /// 依營收歸屬規則彙總訂單；取消與報價中客戶仍保留
    ///
    /// - Parameter orders: 目前訂單清單
    /// - Returns: 依累計消費由高到低排序的客戶列
    static func aggregate(orders: [LedgerOrder]) -> [CustomerRow] {
        let grouped = Dictionary(grouping: orders) { $0.customer.name }
        let contributingIDs = Set(LedgerOrder.revenueAttributionOrders(from: orders).map(\.id))

        return grouped
            .compactMap { name, list in
                guard let first = list.first else {
                    return nil
                }
                let contributing = list.filter { contributingIDs.contains($0.id) }
                let totalSpent = contributing.reduce(Decimal.zero) { total, order in
                    total + order.summary.revenue
                }
                let lastDate = list.map(\.date).max() ?? first.date

                return CustomerRow(
                    name: name,
                    initials: first.customer.initials,
                    tier: first.customer.tier,
                    orderCount: contributing.count,
                    totalSpent: totalSpent,
                    lastOrderDate: lastDate
                )
            }
            .sorted { lhs, rhs in
                lhs.totalSpent > rhs.totalSpent
            }
    }
}

// MARK: - Identifiable

extension CustomerRow: Identifiable {

    /// 用客戶姓名當識別值 (同名客戶會被聚合成一筆)
    var id: String {
        name
    }
}
