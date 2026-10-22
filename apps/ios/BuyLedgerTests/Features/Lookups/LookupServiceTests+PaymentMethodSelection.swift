//
//  LookupServiceTests+PaymentMethodSelection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

extension LookupServiceTests {

    /// 計算資料庫內使用指定付款方式的訂單筆數
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`
    @Test
    func countOrders_三筆訂單中兩筆使用信用卡_回傳二筆() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let orders = [
            Self.makePaymentOrder(id: "COUNT-A", paymentMethod: "信用卡"),
            Self.makePaymentOrder(id: "COUNT-B", paymentMethod: "信用卡"),
            Self.makePaymentOrder(id: "COUNT-C", paymentMethod: "現金"),
        ]
        try await OrderServiceTests.seed(orders, database: database)

        // When
        let count = try await service.countOrders("信用卡")

        // Then
        #expect(count == 2)
    }

    /// 在交易內依當下的付款方式選取訂單，其他付款方式的訂單維持原值
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`；
    ///   未取得訂單時由 `#require` 丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_資料庫含其他付款方式_只重算當下使用原名稱的訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let original = Self.makePaymentOrder(id: "PM-MATCH", paymentMethod: "匯款")
        let other = Self.makePaymentOrder(id: "PM-OTHER", paymentMethod: "現金")
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "匯款", flags: .none))
        try await OrderServiceTests.seed([original, other], database: database)

        // When
        let updated = try await service.applyPaymentMethodEdit("匯款", "銀行匯款", .none)

        // Then
        #expect(updated.map(\.id) == ["PM-MATCH"])
        let stored = try #require(try await Self.fetchOrder(id: "PM-MATCH", from: database))
        #expect(stored.paymentMethod == "銀行匯款")
        #expect(stored.cardlessDeductionAmount == 0)
        #expect(stored.cardlessSupplementAmount == 0)
        #expect(stored.reconciliationStatus == "")
        #expect(stored.isCashOnDelivery == false)
        let unchanged = try #require(try await Self.fetchOrder(id: "PM-OTHER", from: database))
        #expect(LedgerOrder.normalizingItemIdentifiers(unchanged) == other)
    }

    /// 未經畫面載入的訂單仍在交易內重算並回傳，貨到付款運費計入成本 (規格範例「orders not yet loaded into memory」)
    ///
    /// - Throws: 資料庫讀寫失敗時丟出 `PersistenceError`；
    ///   未取得兩筆訂單時由 `#require` 丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_資料庫內兩筆信用卡訂單_皆重算貨到付款成本並回傳() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let orders = [
            Self.makePaymentOrder(id: "PM-A", paymentMethod: "信用卡", isCashOnDelivery: false),
            Self.makePaymentOrder(id: "PM-B", paymentMethod: "信用卡", isCashOnDelivery: false),
        ]
        let flags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: true
        )
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "信用卡", flags: .none))
        try await OrderServiceTests.seed(orders, database: database)

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
            let stored = try #require(try await Self.fetchOrder(id: id, from: database))
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

    /// 空白目標名稱在建立寫入交易前直接回傳空陣列
    ///
    /// - Throws: 呼叫失敗時丟出 `PersistenceError`
    @Test
    func applyPaymentMethodEdit_新名稱為空白_不開交易且回傳空陣列() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let mock = MockBuyLedgerDatabase(database: database)
        let service = Self.makeService(database: mock)

        // When
        let updated = try await service.applyPaymentMethodEdit("信用卡", " \n\t ", .none)

        // Then
        #expect(updated == [])
        #expect(mock.writeCallCount == 0)
    }
}
