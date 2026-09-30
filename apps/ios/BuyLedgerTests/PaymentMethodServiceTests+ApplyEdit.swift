//
//  PaymentMethodServiceTests+ApplyEdit.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension PaymentMethodServiceTests {

    /// 編輯付款方式後讀回更新的主檔與正規化訂單
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   編輯查詢失敗時丟出 `PaymentMethodPersistenceError.storage(.fetchFailed(underlying:))`；
    ///   編輯儲存失敗時丟出 `.storage(.saveFailed(underlying:))`；找不到訂單時丟出 `.orderNotFound(id:)`；
    ///   `#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_付款方式變更_讀回更新主檔與正規化訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let original = Self.makePaymentOrder(id: "PM-PERSIST", paymentMethod: "匯款")
        let corrected = original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(.none)
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        try await service.addPaymentMethod("匯款", originalFlags)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        try await service.applyPaymentMethodEdit(
            "匯款",
            " 銀行匯款 ",
            .none,
            [corrected]
        )

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(paymentMethods == [PaymentMethodInfo(name: "銀行匯款", flags: .none)])
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(corrected)
        )
    }

    /// 編輯訂單付款方式時保留既有照片
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   編輯查詢失敗時丟出 `PaymentMethodPersistenceError.storage(.fetchFailed(underlying:))`；
    ///   編輯儲存失敗時丟出 `.storage(.saveFailed(underlying:))`；找不到訂單時丟出 `.orderNotFound(id:)`；
    ///   `#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_訂單有照片_保留既有照片() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x40])
        let original = Self.makePaymentOrder(id: "PM-PHOTO", paymentMethod: "匯款", photos: [photo])
        let corrected = Self.makePaymentOrder(
            id: "PM-PHOTO",
            paymentMethod: "銀行匯款",
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        try await service.addPaymentMethod("匯款", .none)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        try await service.applyPaymentMethodEdit(
            "匯款",
            "銀行匯款",
            .none,
            [corrected]
        )

        // Then
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(storedOrder.paymentMethod == "銀行匯款")
        #expect(storedOrder.photos == [photo])
    }

    /// 快照包含不存在的訂單時保留 `orderNotFound` 錯誤與原資料
    ///
    /// - Throws: 資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；`#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_快照包含不存在訂單_保留找不到訂單錯誤與原資料() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let original = Self.makePaymentOrder(id: "PM-ATOMIC", paymentMethod: "匯款")
        let corrected = Self.makePaymentOrder(
            id: original.id,
            paymentMethod: "銀行匯款",
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        let missing = Self.makePaymentOrder(
            id: "order-404",
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
        var actualError: PaymentMethodPersistenceError?
        try await service.addPaymentMethod("匯款", originalFlags)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        do throws(PaymentMethodPersistenceError) {
            try await service.applyPaymentMethodEdit(
                "匯款",
                "銀行匯款",
                .none,
                [corrected, missing]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let missingOrderID: LedgerOrder.ID?
        switch error {
        case .orderNotFound(let id):
            missingOrderID = id

        case .storage:
            missingOrderID = nil
        }
        let actualMissingOrderID = try #require(missingOrderID)
        #expect(actualMissingOrderID == "order-404")
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: originalFlags)])
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
        let missingOrder = try await Self.fetchOrder(id: missing.id, from: database)
        #expect(missingOrder == nil)
    }

    /// 真正 save 失敗後付款方式與訂單都維持原值
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；
    ///   資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；`#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_交易儲存失敗_維持主檔與訂單原值() async throws {
        // Given
        let original = Self.makePaymentOrder(id: "PM-SAVE-FAIL", paymentMethod: "匯款")
        let corrected = Self.makePaymentOrder(
            id: original.id,
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
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [original])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let seedService = Self.makeService(database: database)
        try await seedService.addPaymentMethod("匯款", originalFlags)
        let mockDatabase = MockBuyLedgerDatabase(database: database)
        mockDatabase.mode = .saveFailureAfterBody
        let failingService = Self.makeService(database: mockDatabase)

        var actualError: PaymentMethodPersistenceError?

        // When
        do throws(PaymentMethodPersistenceError) {
            try await failingService.applyPaymentMethodEdit(
                "匯款",
                "銀行匯款",
                .none,
                [corrected]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualStorageError: PersistenceError?
        switch error {
        case .storage(let storageError):
            actualStorageError = storageError

        case .orderNotFound:
            actualStorageError = nil
        }
        let storageError = try #require(actualStorageError)
        let isSaveFailure: Bool
        switch storageError {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        #expect(isSaveFailure)
        let paymentMethods = try await seedService.fetchPaymentMethodInfos()
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: originalFlags)])
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }

    /// 空白新名稱不執行付款方式或訂單編輯
    ///
    /// - Throws: 資料庫查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   資料庫儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   編輯查詢失敗時丟出 `PaymentMethodPersistenceError.storage(.fetchFailed(underlying:))`；
    ///   編輯儲存失敗時丟出 `.storage(.saveFailed(underlying:))`；找不到訂單時丟出 `.orderNotFound(id:)`；
    ///   讀回訂單不存在時由 `try #require` 丟出測試斷言錯誤
    @Test
    func applyPaymentMethodEdit_新名稱為空白_不修改付款方式與訂單() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let service = Self.makeService(database: database)
        let original = Self.makePaymentOrder(id: "PM-EMPTY", paymentMethod: "匯款")
        let corrected = Self.makePaymentOrder(
            id: original.id,
            paymentMethod: "",
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
        try await service.addPaymentMethod("匯款", originalFlags)
        try await database.write { context throws(PersistenceError) in
            context.insert(OrderRecord(order: original))
        }

        // When
        try await service.applyPaymentMethodEdit(
            "匯款",
            " \n\t ",
            .none,
            [corrected]
        )

        // Then
        let paymentMethods = try await service.fetchPaymentMethodInfos()
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: originalFlags)])
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
