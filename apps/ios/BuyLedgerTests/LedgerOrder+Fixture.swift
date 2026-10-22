//
//  LedgerOrder+Fixture.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/22.
//

import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension LedgerOrder {

    /// 建立欄位都有固定預設值的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶資料
    ///   - status: 訂單狀態
    ///   - currency: 商品幣別
    ///   - date: 訂單日期
    ///   - items: 商品項目
    ///   - itemCost: 商品成本
    ///   - domesticShipping: 國內運費成本
    ///   - internationalShipping: 國際運費成本
    ///   - foreignDomesticShipping: 商品來源國的國內運費成本
    ///   - cardFeeRate: 刷卡手續費比例
    ///   - platformFeeRate: 平台手續費比例
    ///   - paymentFeeRate: 金流手續費比例
    ///   - chargedAmount: 向客戶收取的金額
    ///   - cardlessDeductionAmount: 無卡付款的折抵金額
    ///   - cardlessSupplementAmount: 無卡付款的補款金額
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - notes: 訂單備註
    ///   - reconciliationStatus: 對帳狀態
    ///   - campaignNames: 所屬開團名稱
    ///   - paymentReceiptStatus: 收款狀態
    ///   - isCashOnDelivery: 是否為貨到付款
    ///   - photos: 訂單照片
    ///   - mergedSourceIDs: 合併前的訂單編號
    /// - Returns: 固定內容的測試訂單
    static func fixture(
        id: String = "fixture-order-id",
        customer: LedgerCustomer = LedgerCustomer(
            name: "測試客戶",
            initials: "TC",
            tier: .regular
        ),
        status: OrderStatus = .confirmed,
        currency: CurrencyCode = .twd,
        date: Date = Date(timeIntervalSince1970: 0),
        items: [LedgerOrderItem] = [],
        itemCost: Decimal = 0,
        domesticShipping: Decimal = 0,
        internationalShipping: Decimal = 0,
        foreignDomesticShipping: Decimal = 0,
        cardFeeRate: Decimal = 0,
        platformFeeRate: Decimal = 0,
        paymentFeeRate: Decimal = 0,
        chargedAmount: Decimal = 0,
        cardlessDeductionAmount: Decimal = 0,
        cardlessSupplementAmount: Decimal = 0,
        orderSource: String = "測試來源",
        categories: [String] = [],
        paymentMethod: String = "測試付款方式",
        notes: String = "",
        reconciliationStatus: String = "",
        campaignNames: [String] = [],
        paymentReceiptStatus: PaymentReceiptStatus = .pending,
        isCashOnDelivery: Bool = false,
        photos: [Data] = [],
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
