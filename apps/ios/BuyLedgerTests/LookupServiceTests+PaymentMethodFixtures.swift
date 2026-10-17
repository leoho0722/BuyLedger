//
//  LookupServiceTests+PaymentMethodFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension LookupServiceTests {

    /// 建立付款方式編輯測試使用的訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - paymentMethod: 付款方式名稱
    ///   - photos: 訂單照片
    ///   - cardlessDeductionAmount: 無卡折讓金額
    ///   - cardlessSupplementAmount: 無卡補貼金額
    ///   - reconciliationStatus: 對帳狀態
    ///   - isCashOnDelivery: 是否為貨到付款
    /// - Returns: 建立的訂單
    static func makePaymentOrder(
        id: String,
        paymentMethod: String,
        photos: [Data] = [],
        cardlessDeductionAmount: Decimal = 750,
        cardlessSupplementAmount: Decimal = 250,
        reconciliationStatus: String = "待對帳",
        isCashOnDelivery: Bool = true
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "付款測試", initials: "PM", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 5_000
                ),
            ],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: []
        )
    }

    /// 以新的 Database read context 讀回指定訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - database: 要讀取的資料庫
    /// - Returns: 找到時轉成領域型別的訂單
    /// - Throws: 查詢或記錄轉換失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchOrder(
        id: String,
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(PersistenceError) -> LedgerOrder? {
        try await database.read { context throws(PersistenceError) in
            let descriptor = FetchDescriptor<OrderRecord>(
                predicate: #Predicate {
                    $0.id == id
                }
            )
            let record = try PersistenceError.mapFetch {
                try context.fetch(descriptor).first
            }
            return try record?.toDomain()
        }
    }
}
