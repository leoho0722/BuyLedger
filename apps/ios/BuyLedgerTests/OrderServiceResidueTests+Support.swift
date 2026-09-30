//
//  OrderServiceResidueTests+Support.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import CoreData
import Testing

@testable import BuyLedger

// MARK: - Nested Types

extension OrderServiceResidueTests {

    /// 可能丟出持久化錯誤的非同步寫入操作
    typealias FailureOperation = () async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension OrderServiceResidueTests {

    /// 驗證指定寫入以違規 relationship 的 save failure 結束
    ///
    /// - Parameter operation: 會觸發注入失敗的寫入
    /// - Throws: 沒有失敗或錯誤不是指定 relationship 限制時由 `#require` 丟出測試斷言錯誤
    static func requireRelationshipSaveFailure(_ operation: FailureOperation) async throws {
        var actualError: PersistenceError?
        do throws(PersistenceError) {
            try await operation()
        } catch {
            actualError = error
        }
        let error = try #require(actualError)
        let underlyingError: (any Error & Sendable)?
        switch error {
        case .saveFailed(let underlying):
            underlyingError = underlying

        case .fetchFailed, .containerCreationFailed:
            underlyingError = nil
        }
        let underlying = try #require(underlyingError)
        try #require((underlying as NSError).domain == NSCocoaErrorDomain)
        try #require(
            (underlying as NSError).code == NSValidationRelationshipExceedsMaximumCountError
        )
    }
}
