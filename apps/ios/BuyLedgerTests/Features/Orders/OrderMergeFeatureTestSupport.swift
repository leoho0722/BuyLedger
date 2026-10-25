//
//  OrderMergeFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation

@testable import BuyLedger

/// 提供訂單合併測試共用的日期脈絡與訂單資料
enum OrderMergeFeatureTestSupport {}

// MARK: - Computed Properties

extension OrderMergeFeatureTestSupport {

    /// 合併流程測試共用的固定時間與行事曆
    static var fixedDateContext: OrderDateContext {
        OrderDateContext(now: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
    }
}

// MARK: - Internal Method

extension OrderMergeFeatureTestSupport {

    /// 建立測試訂單；未指定的欄位使用預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值，同一組測試內須互不相同
    ///   - status: 訂單狀態，決定訂單是否符合合併候選的資格
    ///   - customer: 客戶名稱，預設所有測試訂單屬於同一位客戶
    ///   - currency: 訂單幣別，預設日圓
    ///   - itemName: 商品名稱，預設為示範用的商品名稱
    ///   - date: 訂單日期，預設為固定時間點，不隨執行時間改變
    ///   - photos: 訂單照片，預設沒有照片
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus,
        customer: String = "Alice",
        currency: CurrencyCode = .jpy,
        itemName: String = "示範商品",
        date: Date = Date(timeIntervalSince1970: 1_770_000_000),
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            currency: currency,
            date: date,
            items: [LedgerOrderItem(name: itemName, quantity: 1, unitPrice: 100)],
            itemCost: 100,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: photos,
            mergedSourceIDs: []
        )
    }
}
