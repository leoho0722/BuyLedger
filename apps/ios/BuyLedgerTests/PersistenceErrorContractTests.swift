//
//  PersistenceErrorContractTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/4.
//

import Testing
@testable import BuyLedger

/// 驗證持久化錯誤的分類與資料
struct PersistenceErrorContractTests {
    
    // MARK: - Tests
    
    @Test func storageErrorsRetainTheirCategoryAndMessage() {
        #expect(
            PersistenceError.fetchFailed(message: "fetch failed")
                == .fetchFailed(message: "fetch failed")
        )
        #expect(
            PersistenceError.saveFailed(message: "save failed")
                == .saveFailed(message: "save failed")
        )
        #expect(
            PersistenceError.containerCreationFailed(message: "container failed")
                == .containerCreationFailed(message: "container failed")
        )
    }
    
    @Test func domainErrorsWrapStorageFailuresWithoutLosingTheMessage() {
        let storageError = PersistenceError.saveFailed(message: "disk is full")
        
        #expect(OrderPersistenceError.storage(storageError) == .storage(storageError))
        #expect(PaymentMethodPersistenceError.storage(storageError) == .storage(storageError))
        #expect(CurrencyMetadataPersistenceError.storage(storageError) == .storage(storageError))
    }
    
    @Test func currencyMetadataRejectsAnEmptyCodeListAsADomainError() {
        #expect(CurrencyMetadataPersistenceError.emptyCodeList == .emptyCodeList)
    }
    
    @Test func recoveryErrorsIdentifyTheFileThatCouldNotMove() {
        let error = PersistenceRecoveryError.fileMoveFailed(
            fileName: "BuyLedger.store",
            message: "permission denied"
        )
        
        #expect(
            error
                == .fileMoveFailed(
                    fileName: "BuyLedger.store",
                    message: "permission denied"
                )
        )
    }
}
