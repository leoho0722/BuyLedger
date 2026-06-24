//
//  OrderSummary.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單財務試算後的摘要
struct OrderSummary: Equatable {

    // MARK: - Data Properties

    /// 實際收款
    let revenue: Decimal

    /// 刷卡手續費
    let cardFee: Decimal

    /// 平台手續費 (無條件進位到整數)
    let platformFee: Decimal

    /// 金流手續費
    let paymentFee: Decimal

    /// 刷卡、平台與金流手續費的合計
    let fees: Decimal

    /// 總成本
    let totalCost: Decimal

    /// 貨到付款時計入總成本的運費合計 (國內 + 國際 + 來源國當地國內運費)
    ///
    /// 非貨到付款訂單一律為 `0`。貨到付款收取的金額已含預估運費，因此這三種運費計入 ``totalCost``；提供此欄位讓成本拆解能單獨列出該項
    let codShippingCost: Decimal

    /// 稅費與成本後的獲利
    let profit: Decimal

    /// 獲利相對收款的比例
    let margin: Decimal

    // MARK: - Init

    /// 依訂單資料建立財務摘要
    ///
    /// 公式重點：
    /// - `revenue = chargedAmount + cardlessSupplementAmount − cardlessDeductionAmount`，無卡折抵自 revenue 中扣除、無卡補款加回 revenue；對非無卡訂單兩個欄位皆為 `0`，等同維持舊行為
    /// - 手續費仍以 `chargedAmount` 為基準，因為刷卡 / 平台 / 金流手續費的計算對象是原始收款金額，不會因為使用者另外用儲值金折抵或事後補款而改變
    /// - `totalCost = itemCost + fees + codShippingCost`：國內運費、國際運費與來源國當地國內運費「正常情況下」由客人另外支付、不計入成本 (`codShippingCost == 0`)；但 **貨到付款** (`order.isCashOnDelivery == true`) 收取的金額已含預估的三種運費，因此 `codShippingCost = domesticShipping + internationalShipping + foreignDomesticShipping` 計入總成本，還原真實獲利
    /// - `profit = revenue − totalCost`、`margin = profit / revenue`；`revenue == 0` 時 margin 維持 `0`
    /// - Parameter order: 要計算的訂單
    init(order: LedgerOrder) {
        let cardFee = order.chargedAmount * order.cardFeeRate
        let platformFee = (order.chargedAmount * order.platformFeeRate).roundedUpToInteger()
        let paymentFee = order.chargedAmount * order.paymentFeeRate
        let fees = cardFee + platformFee + paymentFee
        let revenue = order.chargedAmount
            + order.cardlessSupplementAmount
            - order.cardlessDeductionAmount
        // 貨到付款收取的金額已含預估的三種運費，故計入總成本；一般訂單運費由客人另付、不計入成本，故為 0
        let codShippingCost: Decimal
        if order.isCashOnDelivery {
            codShippingCost = order.domesticShipping
                + order.internationalShipping
                + order.foreignDomesticShipping
        } else {
            codShippingCost = 0
        }
        let totalCost = order.itemCost + fees + codShippingCost
        let profit = revenue - totalCost

        self.revenue = revenue
        self.cardFee = cardFee
        self.platformFee = platformFee
        self.paymentFee = paymentFee
        self.fees = fees
        self.totalCost = totalCost
        self.codShippingCost = codShippingCost
        self.profit = profit
        self.margin = revenue == 0 ? 0 : profit / revenue
    }
}

private extension Decimal {

    /// 對 `Decimal` 套用無條件進位到整數
    func roundedUpToInteger() -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, 0, .up)
        return result
    }
}
