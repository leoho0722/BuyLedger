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
    let codShippingCost: Decimal
    
    /// 稅費與成本後的獲利
    let profit: Decimal
    
    /// 獲利相對收款的比例
    let margin: Decimal
    
    // MARK: - Init
    
    /// 依訂單資料建立財務摘要
    ///
    /// - `revenue` = `chargedAmount` + `cardlessSupplementAmount` - `cardlessDeductionAmount`
    ///   非無卡訂單兩欄皆為 `0`
    ///   寫入層限制折抵不超過收款；舊資料仍可能為負
    /// - 手續費以原始收款 `chargedAmount` 計算，不受無卡補款或折抵影響
    /// - `totalCost` = `itemCost` + `fees` + `codShippingCost`
    ///   只有貨到付款會計入國內、國際與來源國當地運費；一般訂單為 `0`
    /// - `profit` = `revenue` - `totalCost`
    /// - `margin` = `profit / revenue`
    ///   `revenue == 0` 時為 `0`；呈現層對 `revenue <= 0` 顯示空值
    /// - Parameter order: 要計算的訂單
    init(order: LedgerOrder) {
        let cardFee = order.chargedAmount * order.cardFeeRate
        let platformFee = (order.chargedAmount * order.platformFeeRate).roundedUpToInteger()
        let paymentFee = order.chargedAmount * order.paymentFeeRate
        let fees = cardFee + platformFee + paymentFee
        let revenue = order.chargedAmount + order.cardlessSupplementAmount - order.cardlessDeductionAmount
        // 貨到付款已含運費，計入成本；其他訂單由客人另付。
        let codShippingCost: Decimal
        if order.isCashOnDelivery {
            codShippingCost =
            order.domesticShipping
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
