//
//  LookupServiceTests+PaymentMethodAtomicity.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

extension LookupServiceTests {

    /// 真正 save 失敗後付款方式與訂單都維持原值
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；
    ///   資料庫讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；`#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_交易儲存失敗_維持主檔與訂單原值() async throws {
        // Given
        let original = Self.makePaymentOrder(id: "PM-SAVE-FAIL", paymentMethod: "匯款")
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
        try await seedService.addItem(
            .paymentMethod,
            LookupItemAddition(name: "匯款", flags: originalFlags)
        )
        let mockDatabase = MockBuyLedgerDatabase(database: database)
        mockDatabase.mode = .saveFailureAfterBody
        let failingService = Self.makeService(database: mockDatabase)

        var actualError: PersistenceError?

        // When
        do throws(PersistenceError) {
            _ = try await failingService.applyPaymentMethodEdit(
                "匯款",
                "orders.edit.label.bankTransfer",
                .none
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isSaveFailure: Bool
        switch error {
        case .saveFailed:
            isSaveFailure = true

        case .fetchFailed, .containerCreationFailed:
            isSaveFailure = false
        }
        #expect(isSaveFailure)
        let paymentMethods = try await seedService.fetchItems(.paymentMethod).paymentMethods
        #expect(paymentMethods == [PaymentMethodInfo(name: "匯款", flags: originalFlags)])
        let fetchedOrder = try await Self.fetchOrder(id: original.id, from: database)
        let storedOrder = try #require(fetchedOrder)
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
