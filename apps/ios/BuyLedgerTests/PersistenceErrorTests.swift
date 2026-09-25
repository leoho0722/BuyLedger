//
//  PersistenceErrorTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證持久化基礎錯誤保留來源錯誤資訊
struct PersistenceErrorTests {

    // MARK: - Tests

    /// fetch 失敗時保留來源錯誤的 NSError 資訊
    @Test func mapFetchWhenOperationFailsPreservesUnderlyingMetadata() {
        // Given

        let sourceError = NSError(
            domain: "com.leoho.BuyLedger.persistence-test",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "fetch unavailable"]
        )

        do {
            // When

            _ = try PersistenceError.mapFetch {
                throw sourceError
            }

            // Then

            Issue.record("預期 mapFetch 會拋出 PersistenceError。")
        } catch {
            switch error {
            case let .fetchFailed(underlying):
                let bridgedError = underlying as NSError
                #expect(bridgedError.domain == sourceError.domain)
                #expect(bridgedError.code == sourceError.code)
                #expect(bridgedError.localizedDescription == sourceError.localizedDescription)
            case .saveFailed, .containerCreationFailed:
                Issue.record("預期為 fetchFailed PersistenceError。")
            }
        }
    }

    /// save 失敗時保留來源錯誤的 NSError 資訊
    @Test func mapSaveWhenOperationFailsPreservesUnderlyingMetadata() {
        // Given

        let sourceError = NSError(
            domain: "com.leoho.BuyLedger.persistence-test",
            code: 402,
            userInfo: [NSLocalizedDescriptionKey: "save unavailable"]
        )

        do {
            // When

            try PersistenceError.mapSave {
                throw sourceError
            }

            // Then

            Issue.record("預期 mapSave 會拋出 PersistenceError。")
        } catch {
            switch error {
            case .fetchFailed, .containerCreationFailed:
                Issue.record("預期為 saveFailed PersistenceError。")
            case let .saveFailed(underlying):
                let bridgedError = underlying as NSError
                #expect(bridgedError.domain == sourceError.domain)
                #expect(bridgedError.code == sourceError.code)
                #expect(bridgedError.localizedDescription == sourceError.localizedDescription)
            }
        }
    }
}
