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

    /// 商品來源國當地的「國內運費」成本（折合 TWD）。例如賣家把商品從日本國內出貨到集運倉的運送費。
    let foreignDomesticShipping: Decimal

    /// 刷卡手續費比例。
    let cardFeeRate: Decimal

    /// 平台手續費比例。
    let platformFeeRate: Decimal

    /// 金流手續費比例（0–1，例如 0.005 = 0.5%）；用於 LINE Pay、街口、信用卡之外的第三方金流抽成。
    let paymentFeeRate: Decimal

    /// 實際向客戶收款的新台幣金額。
    let chargedAmount: Decimal

    /// 無卡折抵金額（TWD）。
    ///
    /// 用於「無卡」類付款方式紀錄客戶以儲值金、購物金等方式折抵的金額；折抵會從 ``OrderSummary/revenue`` 中扣除。非無卡訂單一律以 `0` 帶入。
    let cardlessDeductionAmount: Decimal

    /// 無卡補款金額（TWD）。
    ///
    /// 用於「無卡」類付款方式紀錄客戶以 ATM 轉帳等方式補繳的金額；補款會加到 ``OrderSummary/revenue`` 中。非無卡訂單一律以 `0` 帶入。
    let cardlessSupplementAmount: Decimal

    /// 商品類別。
    let category: String

    /// 付款方式。
    let paymentMethod: String

    // MARK: - Computed Properties

    /// 訂單的財務摘要。
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 列表中顯示的主要商品描述。
    var primaryItemDescription: String {
        guard let firstItem = items.first else {
            return "未命名商品"
        }

        if items.count == 1 {
            return firstItem.name
        }

        return "\(firstItem.name) +\(items.count - 1)"
    }
}
