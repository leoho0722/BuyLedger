//
//  CurrencyMetadataServiceTests+Refresh.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CurrencyMetadataServiceTests {

    /// 空清單回應回報明確錯誤，且不清除既有快取
    ///
    /// - Throws: seed 失敗時丟出 `.storage(.saveFailed(underlying:))`；`fetchCodes` 讀取快取失敗時
    ///   丟出 `.persistence(.storage(.fetchFailed(underlying:)))`；HTTP response fixture 建立失敗、
    ///   刷新前的快取不是預期的 `TWD`、`USD`，或 `refreshIfStale` 沒有丟出錯誤時由 `#require`
    ///   丟出測試斷言錯誤
    @Test
    func refreshIfStale_空清單_回報錯誤並保留既有快取() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        let cachedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try await Self.seedCache(["TWD", "USD"], at: cachedAt, in: database)
        let httpClient = MockHTTPClient()
        let responseBody = Data(#"{"result":"success","supported_codes":[]}"#.utf8)
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let before = try await service.fetchCodes()
        try #require(before == [CurrencyCode(rawValue: "TWD"), .usd])
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isEmptyCodeList: Bool
        switch error {
        case .persistence(.emptyCodeList):
            isEmptyCodeList = true

        case .persistence(.storage), .api:
            isEmptyCodeList = false
        }
        #expect(isEmptyCodeList)
        let after = try await service.fetchCodes()
        #expect(after == before)
    }

    /// 非空遠端清單取代既有快取並依自然語言順序回傳
    ///
    /// - Throws: seed 失敗時丟出 `.storage(.saveFailed(underlying:))`；刷新時 API 失敗丟出
    ///   `.api(.invalidKey)`、`.api(.transport(underlying:))`、`.api(.http(statusCode:))`、
    ///   `.api(.decoding(underlying:))`、`.api(.quotaExceeded)` 或 `.api(.apiError(code:))`；
    ///   快取讀取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`；
    ///   儲存失敗時丟出 `.persistence(.storage(.saveFailed(underlying:)))`；HTTP response fixture
    ///   建立失敗時由 `#require` 丟出測試斷言錯誤
    @Test
    func refreshIfStale_非空清單_取代既有快取並排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await Self.seedCache(
            ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000),
            in: database
        )
        let responseBody = Data(
            #"{"result":"success","supported_codes":[["JPY","Japanese Yen"],["EUR","Euro"]]}"#.utf8
        )
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )

        // When
        let didRefresh = try await service.refreshIfStale(0)

        // Then
        let codes = try await service.fetchCodes()
        #expect(didRefresh)
        #expect(codes == [CurrencyCode(rawValue: "EUR"), .jpy])
    }

    /// API 傳輸失敗保留底層錯誤分類並且不改變既有快取
    ///
    /// - Throws: seed 失敗時丟出 `.storage(.saveFailed(underlying:))`；讀取失敗時丟出
    ///   `.persistence(.storage(.fetchFailed(underlying:)))`；錯誤前置清單不符或傳輸錯誤
    ///   不符時由 `#require` 丟出測試斷言錯誤
    @Test
    func refreshIfStale_API傳輸失敗_保留錯誤與既有快取() async throws {
        // Given
        let database = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await Self.seedCache(
            ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000),
            in: database
        )
        let expectedUnderlying = NSError(
            domain: "com.leoho.BuyLedger.currency-metadata-test",
            code: 502,
            userInfo: [NSLocalizedDescriptionKey: "network unavailable"]
        )
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .failure(.transport(underlying: expectedUnderlying))
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let before = try await service.fetchCodes()
        try #require(before == [CurrencyCode(rawValue: "TWD"), .usd])
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let underlying: (any Error & Sendable)?
        switch error {
        case .api(.transport(let actualUnderlying)):
            underlying = actualUnderlying

        case .api(.http), .api(.decoding), .api(.apiError), .api(.quotaExceeded), .api(.invalidKey),
                .persistence:
            underlying = nil
        }
        let actualTransportError = try #require(underlying) as NSError
        #expect(actualTransportError.domain == expectedUnderlying.domain)
        #expect(actualTransportError.code == expectedUnderlying.code)
        #expect(
            actualTransportError.localizedDescription
                == expectedUnderlying.localizedDescription
        )
        let after = try await service.fetchCodes()
        #expect(after == before)
    }

    /// 快取未滿七天 (604,799 秒) 不發請求也不寫入，滿七天 (604,800 秒) 才重新請求並寫入
    ///
    /// - Parameters:
    ///   - ageInSeconds: 快取自上次更新後經過的秒數
    ///   - expectedRefresh: 是否預期重新請求並寫入快取
    /// - Throws: seed 失敗時丟出 `.storage(.saveFailed(underlying:))`；刷新時 API 失敗丟出
    ///   `.api(.invalidKey)`、`.api(.transport(underlying:))`、`.api(.http(statusCode:))`、
    ///   `.api(.decoding(underlying:))`、`.api(.quotaExceeded)` 或 `.api(.apiError(code:))`；
    ///   快取讀取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`；
    ///   儲存失敗時丟出 `.persistence(.storage(.saveFailed(underlying:)))`；HTTP response fixture
    ///   建立失敗時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: [(TimeInterval(604_799), false), (TimeInterval(604_800), true)])
    func refreshIfStale_快取年齡在七天門檻前後_依門檻決定是否刷新(
        ageInSeconds: TimeInterval,
        expectedRefresh: Bool
    ) async throws {
        // Given
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let baseDatabase = BuyLedgerDatabaseTests.makeInMemoryDatabase()
        try await Self.seedCache(
            ["TWD"],
            at: now.addingTimeInterval(-ageInSeconds),
            in: baseDatabase
        )
        let database = MockBuyLedgerDatabase(database: baseDatabase)
        let responseJSON = #"{"result":"success","supported_codes":[["JPY","Japanese Yen"]]}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let configurationStore = Self.makeConfigurationStore(apiKey: "network-test-key")
        let service = Self.makeService(
            database: database,
            httpClient: httpClient,
            configurationStore: configurationStore,
            now: now
        )

        // When
        let didRefresh = try await service.refreshIfStale(604_800)

        // Then
        #expect(didRefresh == expectedRefresh)
        #expect(httpClient.dataCallCount == (expectedRefresh ? 1 : 0))
        #expect(configurationStore.stringCallCount == (expectedRefresh ? 1 : 0))
        #expect(database.writeCallCount == (expectedRefresh ? 1 : 0))
        let codes = try await service.fetchCodes()
        #expect(codes == (expectedRefresh ? [.jpy] : [.twd]))
    }
}
