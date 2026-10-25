//
//  InsightsStatsTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

@testable import BuyLedger

/// 提供分析統計測試共用的訂單資料
enum InsightsStatsTestSupport {}

// MARK: - Internal Method

extension InsightsStatsTestSupport {

    /// 建立供 `InsightsStats` 測試用的訂單，其餘欄位使用固定預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - charged: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - domesticShipping: 國內運費
    ///   - internationalShipping: 國際運費
    ///   - cardFeeRate: 刷卡手續費率，乘上實付金額後計入手續費
    ///   - categories: 商品類別
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    /// - Note: 獲利為實付金額扣除商品成本與刷卡手續費
    /// - Note: 非貨到付款不扣運費
    /// - Note: 平台與金流手續費率固定為零
    static func makeOrder(
        id: String,
        status: OrderStatus,
        date: Date,
        charged: Decimal,
        itemCost: Decimal = 0,
        domesticShipping: Decimal = 0,
        internationalShipping: Decimal = 0,
        cardFeeRate: Decimal = 0,
        categories: [String] = [],
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: date,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: 0,
            cardFeeRate: cardFeeRate,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: categories,
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
