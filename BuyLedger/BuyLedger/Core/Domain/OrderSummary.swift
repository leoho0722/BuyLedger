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
    ///
    /// 公式重點：
    /// - `revenue = chargedAmount + cardlessSupplementAmount − cardlessDeductionAmount`，無卡折抵自 revenue 中扣除、無卡補款加回 revenue；對非無卡訂單兩個欄位皆為 `0`，等同維持舊行為。
    /// - 手續費仍以 `chargedAmount` 為基準，因為刷卡 / 平台 / 金流手續費的計算對象是原始收款金額，不會因為使用者另外用儲值金折抵或事後補款而改變。
    /// - `profit = revenue − totalCost`、`margin = profit / revenue`；`revenue == 0` 時 margin 維持 `0`。
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
        let revenue = order.chargedAmount
            + order.cardlessSupplementAmount
            - order.cardlessDeductionAmount
        let profit = revenue - totalCost

        self.revenue = revenue
        self.fees = fees
        self.totalCost = totalCost
        self.profit = profit
        self.margin = revenue == 0 ? 0 : profit / revenue
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
