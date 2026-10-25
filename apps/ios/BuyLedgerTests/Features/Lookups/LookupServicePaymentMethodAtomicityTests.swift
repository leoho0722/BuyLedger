//
//  LookupServicePaymentMethodAtomicityTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Testing

@testable import BuyLedger

/// `LookupService` 的單元測試，涵蓋付款方式編輯的原子性，以磁碟資料庫搭配 `saveFailureAfterBody` 模擬失敗
struct LookupServicePaymentMethodAtomicityTests {

    /// 驗證交易內容寫入後 save 失敗時，`applyPaymentMethodEdit` 丟出 `saveFailed`，主檔與訂單都維持原值、不留下半套資料
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；seed 寫入失敗時丟出 `PersistenceError.saveFailed(underlying:)`；
    ///   讀回資料庫失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；`#require` 失敗時丟出驗證錯誤
    @Test
    func applyPaymentMethodEdit_交易儲存失敗_維持主檔與訂單原值() async throws {
        // Given
        let original = LookupServiceTestSupport.makePaymentOrder(
            id: "PM-SAVE-FAIL",
            paymentMethod: "匯款"
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        let fixture = try ResidueProbeModels.makeDiskFixture(orders: [original])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let seedService = LookupServiceTestSupport.makeService(database: database)
        try await seedService.addItem(
            .paymentMethod,
            LookupItemAddition(name: "匯款", flags: originalFlags)
        )
        let mockDatabase = MockBuyLedgerDatabase(database: database)
        mockDatabase.mode = .saveFailureAfterBody
        let failingService = LookupServiceTestSupport.makeService(database: mockDatabase)

        var actualError: PersistenceError?

        // When
        do {
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
        let fetchedOrder = try await LookupServiceTestSupport.fetchOrder(
            id: original.id,
            from: database
        )
        let storedOrder = try #require(fetchedOrder)
        #expect(
            LedgerOrder.normalizingItemIdentifiers(storedOrder)
                == LedgerOrder.normalizingItemIdentifiers(original)
        )
    }
}
