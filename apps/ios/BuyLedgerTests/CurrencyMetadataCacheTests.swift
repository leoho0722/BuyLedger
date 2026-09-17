//
//  CurrencyMetadataCacheTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

@MainActor
/// 驗證幣別快取的讀取與更新
struct CurrencyMetadataCacheTests {

    // MARK: - Tests

    @Test func emptyRefreshPreservesExistingCacheAndReportsAnomaly() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        let cachedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try await persistence.replace(codes: ["TWD", "USD"], at: cachedAt)
        let before = try await persistence.fetchAllCodes()

        await #expect(throws: CurrencyMetadataPersistenceError.emptyCodeList) {
            try await persistence.replace(codes: [], at: cachedAt)
        }

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(message: "unused latest")
            },
            fetchSupportedCodes: { [] }
        )
        let repository = CurrencyMetadataRepository.live(
            container: container,
            client: client,
            now: { Date(timeIntervalSince1970: 1_700_000_100) }
        )

        await #expect(throws: CurrencyMetadataRepositoryError.persistence(.emptyCodeList)) {
            _ = try await repository.refreshIfStale(0)
        }

        let after = try await persistence.fetchAllCodes()
        #expect(before == ["TWD", "USD"])
        #expect(after == before)
    }

    @Test func nonEmptyRefreshReplacesExistingCache() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        try await persistence.replace(
            codes: ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(message: "unused latest")
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

        #expect(didRefresh)
        #expect(after == ["EUR", "JPY"])
    }

    @Test func failedRefreshLeavesExistingCacheUnchanged() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let persistence = CurrencyMetadataPersistence(modelContainer: container)
        try await persistence.replace(
            codes: ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let before = try await persistence.fetchAllCodes()
        let expected = APIError.transport(message: "network unavailable")

        let client = ExchangeRateClient(
            fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                throw APIError.transport(message: "unused latest")
            },
            fetchSupportedCodes: { () async throws(APIError) -> [String] in throw expected }
        )
        let repository = CurrencyMetadataRepository.live(
            container: container,
            client: client,
            now: { Date(timeIntervalSince1970: 1_700_000_100) }
        )

        await #expect(throws: CurrencyMetadataRepositoryError.api(expected)) {
            _ = try await repository.refreshIfStale(0)
        }

        let after = try await persistence.fetchAllCodes()
        #expect(after == before)
    }

    /// 空幣別代碼清單應被拒絕並回報明確錯誤
    ///
    /// - Throws: 測試容器建立或錯誤驗證失敗時拋出錯誤
    @Test
    func replaceEmptyCodeList_rejectsWithEmptyCodeListError() async throws(any Error) {
        // Given：建立記憶體中的幣別主檔持久層
        let persistence = CurrencyMetadataPersistence(
            modelContainer: PersistenceContainer.makeInMemory(for: .testing)
        )

        // When：以空清單取代幣別代碼
        var thrownError: CurrencyMetadataPersistenceError?
        do {
            try await persistence.replace(
                codes: [],
                at: Date(timeIntervalSince1970: 1_700_000_000)
            )
        } catch let error {
            thrownError = error
        }

        // Then：持久層回報空清單錯誤
        #expect(thrownError == .emptyCodeList)
    }
}
