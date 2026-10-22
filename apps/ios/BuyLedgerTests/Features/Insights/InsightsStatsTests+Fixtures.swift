//
//  InsightsStatsTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension InsightsStatsTests {

    /// 建立只含 `InsightsStats` 所需欄位的訂單，獲利為實付金額扣除商品成本與刷卡手續費，非貨到付款不扣運費，平台與金流手續費率固定為零
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

    /// 建立指定年月日的 UTC 日期
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    /// - Throws: 年月日無法組成有效日期時丟出
    static func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return try #require(components.date)
    }
}
