//
//  StorageFailureWrappingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證資料庫寫入失敗能保留來源錯誤資訊
struct StorageFailureWrappingTests {

    // MARK: - Tests

    /// 寫入失敗時保留來源錯誤的 domain 與 code
    ///
    /// - Parameter scenario: 要驗證的錯誤型別
    /// - Throws: 轉換結果或錯誤 case 不符時由 `#require` 丟出測試失敗
    @Test(arguments: Scenario.allCases)
    func storage_儲存錯誤_保留來源錯誤網域與代碼(scenario: Scenario) throws {
        // Given
        let persistenceError: PersistenceError = .saveFailed(
            underlying: NSError(domain: "TestDomain", code: 42)
        )

        // When
        let wrappedErrorResult = scenario.unwrappedStorage(persistenceError)

        // Then
        let wrappedError = try #require(wrappedErrorResult)
        let underlying: (any Error & Sendable)?
        switch wrappedError {
        case .saveFailed(let error):
            underlying = error

        case .fetchFailed, .containerCreationFailed:
            underlying = nil
        }
        let actualError = try #require(underlying) as NSError
        #expect(actualError.domain == "TestDomain")
        #expect(actualError.code == 42)
    }
}

// MARK: - Nested Types

extension StorageFailureWrappingTests {

    /// 資料庫寫入錯誤的包裝型別
    enum Scenario: CaseIterable, Sendable {

        /// 基礎持久化錯誤
        case persistence

        /// 訂單持久化錯誤
        case order

        /// 付款方式持久化錯誤
        case paymentMethod

        /// 幣別快取持久化錯誤
        case currencyMetadata

        /// 轉成對應領域錯誤後取出其中的持久化錯誤
        ///
        /// - Parameter error: 要轉換的持久化錯誤
        /// - Returns: 包裝後取出的持久化錯誤；case 不符時為 `nil`
        func unwrappedStorage(_ error: PersistenceError) -> PersistenceError? {
            switch self {
            case .persistence:
                return StorageFailureWrappingTests.wrapped(error, as: PersistenceError.self)

            case .order:
                let wrapped = StorageFailureWrappingTests.wrapped(
                    error,
                    as: OrderPersistenceError.self
                )
                guard case .storage(let persistenceError) = wrapped else {
                    return nil
                }
                return persistenceError

            case .paymentMethod:
                let wrapped = StorageFailureWrappingTests.wrapped(
                    error,
                    as: PaymentMethodPersistenceError.self
                )
                guard case .storage(let persistenceError) = wrapped else {
                    return nil
                }
                return persistenceError

            case .currencyMetadata:
                let wrapped = StorageFailureWrappingTests.wrapped(
                    error,
                    as: CurrencyMetadataPersistenceError.self
                )
                guard case .storage(let persistenceError) = wrapped else {
                    return nil
                }
                return persistenceError
            }
        }
    }
}

// MARK: - Private Method

private extension StorageFailureWrappingTests {

    /// 經由包裝 protocol 建立指定錯誤型別
    ///
    /// - Parameters:
    ///   - error: 要包裝的持久化錯誤
    ///   - type: 呼叫端錯誤型別
    /// - Returns: 指定錯誤型別的包裝結果
    static func wrapped<Failure: StorageFailureWrapping>(
        _ error: PersistenceError,
        as type: Failure.Type
    ) -> Failure {
        type.storage(error)
    }
}
