//
//  LookupServicePaymentMethodEditsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋付款方式編輯，以記憶體內資料庫讀回主檔與訂單，檢查更新結果、照片保留與空白名稱的處理
struct LookupServicePaymentMethodEditsTests {

    /// 驗證付款方式改為含前後空白的新名稱且旗標改為 `none` 時，讀回的主檔為修剪後的名稱，訂單依新旗標正規化
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   `#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_付款方式變更_讀回更新主檔與正規化訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let original = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-PERSIST",
            paymentMethod: "匯款"
        )
        let corrected = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-PERSIST",
            paymentMethod: "銀行匯款",
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "匯款", flags: originalFlags)
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        _ = try await service.applyPaymentMethodEdit("匯款", " 銀行匯款 ", .none)

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        let fetchedOrder = try await LookupServiceTestSupport.fetchOrder(
            id: original.id,
            from: database
        )
        let storedOrder = try #require(fetchedOrder)
        #expect(paymentMethods == [PaymentMethodInfo(name: "銀行匯款", flags: .none)])
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(corrected)
        )
    }

    /// 驗證編輯付款方式後，資料庫中的照片保持原樣，回傳的訂單則不帶照片位元組
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   `#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_訂單有照片_保留既有照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x40])
        let original = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-PHOTO",
            paymentMethod: "匯款",
            photos: [photo]
        )
        try await service.addItem(.paymentMethod, LookupItemAddition(name: "匯款", flags: .none))
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        let updated = try await service.applyPaymentMethodEdit(
            "匯款",
            "orders.edit.label.bankTransfer",
            .none
        )

        // Then
        let fetchedOrder = try await LookupServiceTestSupport.fetchOrder(
            id: original.id,
            from: database
        )
        let storedOrder = try #require(fetchedOrder)
        #expect(storedOrder.paymentMethod == "orders.edit.label.bankTransfer")
        #expect(storedOrder.photos == [photo])
        #expect(updated.map(\.id) == ["PM-PHOTO"])
        let returnedOrder = try #require(updated.first)
        #expect(returnedOrder.photos == [])
    }

    /// 驗證新名稱只含空白與換行時，`applyPaymentMethodEdit` 不丟錯，付款方式與訂單都維持原樣
    ///
    /// - Throws: 資料庫查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   資料庫儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func applyPaymentMethodEdit_新名稱為空白_不修改付款方式與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = LookupServiceTestSupport.makeService(database: database)
        let original = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-EMPTY",
            paymentMethod: "匯款"
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        try await service.addItem(
            .paymentMethod,
            LookupItemAddition(name: "匯款", flags: originalFlags)
        )
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        _ = try await service.applyPaymentMethodEdit("匯款", " \n\t ", .none)

        // Then
        let paymentMethods = try await service.fetchItems(.paymentMethod).paymentMethods
        let fetchedOrder = try await LookupServiceTestSupport.fetchOrder(
            id: original.id,
            from: database
        )
        let storedOrder = try #require(fetchedOrder)
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: originalFlags)])
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
