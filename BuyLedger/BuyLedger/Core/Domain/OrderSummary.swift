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
        let cardFee = order.chargedAmount * order.cardFeeRate
        let platformFee = (order.chargedAmount * order.platformFeeRate).roundedUpToInteger()
        let paymentFee = order.chargedAmount * order.paymentFeeRate
        let fees = cardFee + platformFee + paymentFee
        let totalCost = order.itemCost
            + order.domesticShipping
            + order.internationalShipping
            + order.foreignDomesticShipping
            + fees
        let profit = order.chargedAmount - totalCost

        self.revenue = order.chargedAmount
        self.fees = fees
        self.totalCost = totalCost
        self.profit = profit
        self.margin = order.chargedAmount == 0 ? 0 : profit / order.chargedAmount
    }
}

private extension Decimal {

    /// 對 `Decimal` 套用無條件進位到整數。
    func roundedUpToInteger() -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, 0, .up)
        return result
    }
}
