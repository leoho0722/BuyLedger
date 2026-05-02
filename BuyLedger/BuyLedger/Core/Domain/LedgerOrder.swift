//
//  LedgerOrder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// BuyLedger 中用於列表、詳情與彙總的訂單資料。
struct LedgerOrder: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 訂單編號。
    let id: String

    /// 訂單客戶。
    let customer: LedgerCustomer

    /// 訂單目前狀態。
    let status: OrderStatus

    /// 商品原始幣別。
    let currency: CurrencyCode

    /// 訂單建立或更新日期。
    let date: Date

    /// 訂單商品項目。
    let items: [LedgerOrderItem]

    /// 商品折合新台幣後的成本。
    let itemCost: Decimal

    /// 國內運費成本。
    let domesticShipping: Decimal

    /// 國際集運成本。
    let internationalShipping: Decimal

    /// 刷卡手續費比例。
    let cardFeeRate: Decimal

    /// 平台手續費比例。
    let platformFeeRate: Decimal

    /// 實際向客戶收款的新台幣金額。
    let chargedAmount: Decimal

    /// 商品類別。
    let category: String

    // MARK: - Calculated Properties

    /// 訂單的財務摘要。
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 列表中顯示的主要商品描述。
    var primaryItemDescription: String {
        guard let firstItem = items.first else { return "未命名商品" }

        if items.count == 1 {
            return firstItem.name
        }

        return "\(firstItem.name) +\(items.count - 1)"
    }
}
