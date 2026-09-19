//
//  CurrencyMetadataCacheTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/07/29.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

@MainActor
/// 驗證幣別快取的讀取與更新
struct CurrencyMetadataCacheTests {

    // MARK: - Tests

    /// 驗證幣別快取在此情境下的資料與錯誤
    @Test func emptyRefreshPreservesExistingCacheAndReportsAnomaly() async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        let cachedAt = Date(timeIntervalSince1970: 1_700_000_000)
        // When

        try await persistence.replace(codes: ["TWD", "USD"], at: cachedAt)
        let before = try await persistence.fetchAllCodes()

        do {
            try await persistence.replace(codes: [], at: cachedAt)
            // Then

            Issue.record("預期會拋出 emptyCodeList 錯誤。")
        } catch {
            switch error {
            case .emptyCodeList:
                break
            case .storage:
                Issue.record("預期為 emptyCodeList 錯誤。")
            }
        }

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(
                    underlying: TestDependencies.makeUnderlyingError(message: "unused latest")
                )
            },
            fetchSupportedCodes: { [] }
        )
        let repository = CurrencyMetadataRepository.live(
            container: container,
            client: client,
            now: { Date(timeIntervalSince1970: 1_700_000_100) }
        )

        do {
            _ = try await repository.refreshIfStale(0)
            Issue.record("預期會拋出空幣別清單錯誤。")
        } catch {
            switch error {
            case let .persistence(persistenceError):
                switch persistenceError {
                case .emptyCodeList:
                    break
                case .storage:
                    Issue.record("預期為空清單持久化錯誤，實際為 \(persistenceError)。")
                }
            case .api:
                Issue.record("預期為持久化 repository 錯誤，實際為 API 錯誤。")
            }
        }

        let after = try await persistence.fetchAllCodes()
        #expect(before == ["TWD", "USD"])
        #expect(after == before)
    }

    /// 驗證幣別快取在此情境下的資料與錯誤
    @Test func nonEmptyRefreshReplacesExistingCache() async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        // When

        try await persistence.replace(
            codes: ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(
                    underlying: TestDependencies.makeUnderlyingError(message: "unused latest")
                )
            },
            fetchSupportedCodes: { ["JPY", "EUR"] }
        )
        let repository = CurrencyMetadataRepository.live(
            container: container,
            client: client,
            now: { Date(timeIntervalSince1970: 1_700_000_100) }
        )

        let didRefresh = try await repository.refreshIfStale(0)
        let after = try await persistence.fetchAllCodes()

        // Then

        #expect(didRefresh)
        #expect(after == ["EUR", "JPY"])
    }

    /// 驗證幣別快取在此情境下的資料與錯誤
    @Test func failedRefreshLeavesExistingCacheUnchanged() async throws(any Error) {
        // Given

        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        // When

        try await persistence.replace(
            codes: ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let before = try await persistence.fetchAllCodes()
        let expectedUnderlying = NSError(
            domain: "com.leoho.BuyLedger.currency-metadata-test",
            code: 502,
            userInfo: [NSLocalizedDescriptionKey: "network unavailable"]
        )
        let expected = APIError.transport(underlying: expectedUnderlying)

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(
                    underlying: TestDependencies.makeUnderlyingError(message: "unused latest")
                )
            },
            fetchSupportedCodes: { () async throws(APIError) -> [String] in throw expected }
        )
        let repository = CurrencyMetadataRepository.live(
            container: container,
            client: client,
            now: { Date(timeIntervalSince1970: 1_700_000_100) }
        )

        do {
            _ = try await repository.refreshIfStale(0)
            // Then

            Issue.record("預期會拋出 API repository 錯誤。")
        } catch {
            switch error {
            case let .api(apiError):
                switch apiError {
                case let .transport(underlying):
                    let actualUnderlying = underlying as NSError
                    #expect(actualUnderlying.domain == expectedUnderlying.domain)
                    #expect(actualUnderlying.code == expectedUnderlying.code)
                    #expect(
                        actualUnderlying.localizedDescription
                            == expectedUnderlying.localizedDescription
                    )
                case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
                    Issue.record("預期為帶 NSError 底層錯誤的 API transport 錯誤。")
                }
            case .persistence:
                Issue.record("預期為 API repository 錯誤，實際為持久化錯誤。")
            }
        }

        let after = try await persistence.fetchAllCodes()
        #expect(after == before)
    }

    /// 空幣別代碼清單應被拒絕並回報明確錯誤
    ///
    /// - Throws: 測試容器建立或錯誤驗證失敗時拋出錯誤
    @Test
    func replaceEmptyCodeListRejectsWithEmptyCodeListError() async throws(any Error) {
        // Given：建立記憶體中的幣別主檔持久層
        let persistence = CurrencyMetadataPersistence(
            modelContainer: PersistenceContainer.makeInMemory(for: .testing)
        )

        // When
        var thrownError: CurrencyMetadataPersistenceError?
        do {
            try await persistence.replace(
                codes: [],
                at: Date(timeIntervalSince1970: 1_700_000_000)
            )
        } catch let error {
            thrownError = error
        }

        // Then
        guard let thrownError else {
            Issue.record("預期為 emptyCodeList 錯誤。")
            return
        }
        guard case .emptyCodeList = thrownError else {
            Issue.record("預期為 emptyCodeList 錯誤。")
            return
        }
    }
}
