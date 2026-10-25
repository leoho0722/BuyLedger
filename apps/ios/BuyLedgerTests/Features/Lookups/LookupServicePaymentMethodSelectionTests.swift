//
//  LookupServicePaymentMethodSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋付款方式更正，以資料庫內的訂單計算筆數並選出要重算的訂單
struct LookupServicePaymentMethodSelectionTests {

    /// 驗證 `countOrders` 只計入使用指定付款方式的訂單，三筆中兩筆為信用卡時回傳 2
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`
    @Test
    func countOrders_三筆訂單中兩筆使用信用卡_回傳二筆() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let orders = [
            LookupServiceTestSupport.makePaymentOrder(id: "COUNT-A", paymentMethod: "信用卡"),
            LookupServiceTestSupport.makePaymentOrder(id: "COUNT-B", paymentMethod: "信用卡"),
            LookupServiceTestSupport.makePaymentOrder(id: "COUNT-C", paymentMethod: "現金"),
        ]
        try await OrderServiceTestSupport.seed(orders, database: database)

        // When
        let count = try await service.countOrders("信用卡")

        // Then
        #expect(count == 2)
    }

    /// 驗證 `applyPaymentMethodEdit` 在交易內只重算仍為原名稱的訂單，付款方式為現金的訂單維持原值
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`；
    ///   未取得訂單時由 `#require` 丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_資料庫含其他付款方式_只重算當下使用原名稱的訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let original = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-MATCH",
            paymentMethod: "匯款"
        )
        let other = LookupServiceTestSupport.makePaymentOrder(id: "PM-OTHER", paymentMethod: "現金")
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "匯款", flags: .none))
        try await OrderServiceTestSupport.seed([original, other], database: database)

        // When
        let updated = try await service.applyPaymentMethodEdit("匯款", "銀行匯款", .none)

        // Then
        #expect(updated.map(\.id) == ["PM-MATCH"])
        let stored = try #require(
            try await LookupServiceTestSupport.fetchOrder(id: "PM-MATCH", from: database)
        )
        #expect(stored.paymentMethod == "銀行匯款")
        #expect(stored.cardlessDeductionAmount == 0)
        #expect(stored.cardlessSupplementAmount == 0)
        #expect(stored.reconciliationStatus == "")
        #expect(stored.isCashOnDelivery == false)
        let unchanged = try #require(
            try await LookupServiceTestSupport.fetchOrder(id: "PM-OTHER", from: database)
        )
        #expect(LedgerOrder.normalizingItemIdentifiers(unchanged) == other)
    }

    /// 驗證資料庫內兩筆信用卡訂單未經畫面載入時，`applyPaymentMethodEdit` 仍在交易內重算並回傳兩筆，貨到付款運費計入成本
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`；
    ///   未取得兩筆訂單時由 `#require` 丟出驗證錯誤
    /// - Note: 對應規格範例「orders not yet loaded into memory」
    @Test
    func applyPaymentMethodEdit_資料庫內兩筆信用卡訂單_皆重算貨到付款成本並回傳() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let orders = [
            LookupServiceTestSupport.makePaymentOrder(
                id: "PM-A",
                paymentMethod: "信用卡",
                isCashOnDelivery: false
            ),
            LookupServiceTestSupport.makePaymentOrder(
                id: "PM-B",
                paymentMethod: "信用卡",
                isCashOnDelivery: false
            ),
        ]
        let flags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: true
        )
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "信用卡", flags: .none))
        try await OrderServiceTestSupport.seed(orders, database: database)

        // When
        let updated = try await service.applyPaymentMethodEdit("信用卡", "信用卡", flags)

        // Then
        #expect(updated.map(\.id).sorted() == ["PM-A", "PM-B"])
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "信用卡", flags: flags)])
        for id in ["PM-A", "PM-B"] {
            let returned = try #require(updated.first { $0.id == id })
            #expect(returned.paymentMethod == "信用卡")
            #expect(returned.isCashOnDelivery == true)
            #expect(returned.cardlessDeductionAmount == 0)
            #expect(returned.cardlessSupplementAmount == 0)
            #expect(returned.reconciliationStatus == "")
            let stored = try #require(
                try await LookupServiceTestSupport.fetchOrder(id: id, from: database)
            )
            #expect(stored.paymentMethod == "信用卡")
            #expect(stored.isCashOnDelivery == true)
            #expect(stored.cardlessDeductionAmount == 0)
            #expect(stored.cardlessSupplementAmount == 0)
            #expect(stored.reconciliationStatus == "")
            let summary = OrderSummary(order: stored)
            #expect(summary.revenue == 5_000)
            #expect(summary.codShippingCost == 825)
            #expect(summary.totalCost == 3_825)
            #expect(summary.profit == 1_175)
        }
    }

    /// 驗證目標名稱只含空白與換行時，`applyPaymentMethodEdit` 不開寫入交易，直接回傳空陣列
    ///
    /// - Throws: 呼叫失敗時丟出 `PersistenceError`
    @Test
    func applyPaymentMethodEdit_新名稱為空白_不開交易且回傳空陣列() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let mock = MockBuyLedgerDatabase(database: database)
        let service = LookupServiceTestSupport.makeService(database: mock)

        // When
        let updated = try await service.applyPaymentMethodEdit("信用卡", " \n\t ", .none)

        // Then
        #expect(updated == [])
        #expect(mock.writeCallCount == 0)
    }
}
