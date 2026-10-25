//
//  OrderDraftTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation

@testable import BuyLedger

/// 提供訂單草稿測試共用的最小訂單資料
enum OrderDraftTestSupport {}

// MARK: - Internal Method

extension OrderDraftTestSupport {

    /// 建立僅供草稿建構測試使用的最小訂單；非相關欄位以零值或佔位值填入
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customerName: 客戶名稱
    ///   - initials: 客戶縮寫
    ///   - tier: 客戶等級
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - notes: 備註
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        customerName: String,
        initials: String = "XX",
        tier: CustomerTier = .regular,
        orderSource: String = "來源",
        categories: [String] = ["orders.list.label.category2"],
        paymentMethod: String = "付款",
        notes: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: initials, tier: tier),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
