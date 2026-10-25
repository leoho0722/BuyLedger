//
//  PersistenceErrorTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation
import Testing

@testable import BuyLedger

/// `PersistenceError` 的單元測試，涵蓋來源錯誤資訊的保留
struct PersistenceErrorTests {

    /// 驗證 `mapFetch` 把讀取失敗的錯誤包成 `.fetchFailed`，且保留來源錯誤的網域、代碼與說明
    ///
    /// - Throws: 錯誤不是 `.fetchFailed` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func mapFetch_操作失敗_保留來源錯誤資訊() throws {
        // Given
        let sourceError = NSError(
            domain: "com.leoho.BuyLedger.persistence-test",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "fetch unavailable"]
        )
        var actualError: PersistenceError?

        // When
        do {
            _ = try PersistenceError.mapFetch {
                throw sourceError
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let bridgedError: NSError?
        switch error {
        case .fetchFailed(let underlying):
            bridgedError = underlying as NSError

        case .saveFailed, .containerCreationFailed:
            bridgedError = nil
        }
        let actualBridgedError = try #require(bridgedError)
        #expect(actualBridgedError.domain == sourceError.domain)
        #expect(actualBridgedError.code == sourceError.code)
        #expect(actualBridgedError.localizedDescription == sourceError.localizedDescription)
    }

    /// 驗證 `mapSave` 把寫入失敗的錯誤包成 `.saveFailed`，且保留來源錯誤的網域、代碼與說明
    ///
    /// - Throws: 錯誤不是 `.saveFailed` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func mapSave_操作失敗_保留來源錯誤資訊() throws {
        // Given
        let sourceError = NSError(
            domain: "com.leoho.BuyLedger.persistence-test",
            code: 402,
            userInfo: [NSLocalizedDescriptionKey: "save unavailable"]
        )
        var actualError: PersistenceError?

        // When
        do {
            try PersistenceError.mapSave {
                throw sourceError
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let bridgedError: NSError?
        switch error {
        case .fetchFailed, .containerCreationFailed:
            bridgedError = nil

        case .saveFailed(let underlying):
            bridgedError = underlying as NSError
        }
        let actualBridgedError = try #require(bridgedError)
        #expect(actualBridgedError.domain == sourceError.domain)
        #expect(actualBridgedError.code == sourceError.code)
        #expect(actualBridgedError.localizedDescription == sourceError.localizedDescription)
    }
}
