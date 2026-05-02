//
//  OrderSummary.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單財務試算後的摘要。
struct OrderSummary: Equatable {

    // MARK: - Data Properties

    /// 實際收款。
    let revenue: Decimal

    /// 刷卡與平台手續費。
    let fees: Decimal

    /// 總成本。
    let totalCost: Decimal

    /// 稅費與成本後的獲利。
    let profit: Decimal

    /// 獲利相對收款的比例。
    let margin: Decimal

    // MARK: - Init

    /// 依訂單資料建立財務摘要。
    /// - Parameter order: 要計算的訂單。
    init(order: LedgerOrder) {
        let feeRate = order.cardFeeRate + order.platformFeeRate
        let fees = order.chargedAmount * feeRate
        let totalCost = order.itemCost + order.domesticShipping + order.internationalShipping + fees
        let profit = order.chargedAmount - totalCost

        self.revenue = order.chargedAmount
        self.fees = fees
        self.totalCost = totalCost
        self.profit = profit
        self.margin = order.chargedAmount == 0 ? 0 : profit / order.chargedAmount
    }
}
