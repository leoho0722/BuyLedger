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
}
