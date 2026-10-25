//
//  CurrencyMetadataServiceRefreshTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CurrencyMetadataService` 的單元測試，涵蓋刷新時的快取期限、快取取代與失敗時保留快取
struct CurrencyMetadataServiceRefreshTests {

    /// 驗證 API 回傳空清單時，刷新回報空清單錯誤，既有的 TWD 與 USD 快取保持不變
    ///
    /// - Throws: 建立或讀取快取失敗時丟出持久化錯誤；回應資料、刷新前快取或預期錯誤不符時丟出測試斷言錯誤
    @Test
    func refreshIfStale_空清單_回報錯誤並保留既有快取() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let cachedAt = Date(timeIntervalSince1970: 1_700_000_000)
        try await CurrencyMetadataServiceTestSupport.seedCache(
            ["TWD", "USD"],
            at: cachedAt,
            in: database
        )
        let httpClient = MockHTTPClient()
        let responseBody = Data(#"{"result":"success","supported_codes":[]}"#.utf8)
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let before = try await service.fetchCodes()
        try #require(before == [CurrencyCode(rawValue: "TWD"), .usd])
        var actualError: CurrencyMetadataServiceError?

        // When
        do {
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
        let after = try await service.fetchCodes()
        #expect(isEmptyCodeList)
        #expect(after == [CurrencyCode(rawValue: "TWD"), .usd])
    }

    /// 驗證非空遠端清單取代既有快取，之後讀取依自然排序回傳
    ///
    /// - Throws: 建立、讀取或寫入快取失敗時丟出持久化錯誤；連線、回應或服務端驗證失敗時丟出 API 錯誤
    @Test
    func refreshIfStale_非空清單_取代既有快取並排序() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await CurrencyMetadataServiceTestSupport.seedCache(
            ["TWD", "USD"],
            at: Date(timeIntervalSince1970: 1_700_000_000),
            in: database
        )
        let responseBody = Data(
            #"{"result":"success","supported_codes":[["JPY","Japanese Yen"],["EUR","Euro"]]}"#.utf8
        )
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )

        // When
        let isRefreshed = try await service.refreshIfStale(0)

        // Then
        let codes = try await service.fetchCodes()
        #expect(isRefreshed)
        #expect(codes == [CurrencyCode(rawValue: "EUR"), .jpy])
    }

    /// 驗證 API 傳輸失敗時，回報的底層錯誤與原錯誤的網域、代碼及描述相同，且既有快取不變
    ///
    /// - Throws: 建立或讀取快取失敗時丟出持久化錯誤；前置快取或回報的傳輸錯誤不符時丟出測試斷言錯誤
    @Test
    func refreshIfStale_API傳輸失敗_保留錯誤與既有快取() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await CurrencyMetadataServiceTestSupport.seedCache(
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
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let before = try await service.fetchCodes()
        try #require(before == [CurrencyCode(rawValue: "TWD"), .usd])
        var actualError: CurrencyMetadataServiceError?

        // When
        do {
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
        let after = try await service.fetchCodes()
        #expect(actualTransportError.domain == expectedUnderlying.domain)
        #expect(actualTransportError.code == expectedUnderlying.code)
        #expect(
            actualTransportError.localizedDescription
                == expectedUnderlying.localizedDescription
        )
        #expect(after == [CurrencyCode(rawValue: "TWD"), .usd])
    }

    /// 驗證快取未滿七天 (604,799 秒) 時不發請求也不寫入，滿七天 (604,800 秒) 時才重新請求並寫入
    ///
    /// - Parameter scenario: 快取年齡與預期是否重新請求並寫入快取
    /// - Throws: 建立、讀取或寫入快取失敗時丟出持久化錯誤；連線、回應或服務端驗證失敗時丟出 API 錯誤
    @Test(arguments: [
        CacheAgeCase(
            ageInSeconds: 604_799,
            shouldRefresh: false,
            expectedRequestCount: 0,
            expectedCodes: [.twd]
        ),
        CacheAgeCase(
            ageInSeconds: 604_800,
            shouldRefresh: true,
            expectedRequestCount: 1,
            expectedCodes: [.jpy]
        ),
    ])
    func refreshIfStale_快取年齡在七天門檻前後_依門檻決定是否刷新(scenario: CacheAgeCase) async throws {
        // Given
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let baseDatabase = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        try await CurrencyMetadataServiceTestSupport.seedCache(
            ["TWD"],
            at: now.addingTimeInterval(-scenario.ageInSeconds),
            in: baseDatabase
        )
        let database = MockBuyLedgerDatabase(database: baseDatabase)
        let responseJSON = #"{"result":"success","supported_codes":[["JPY","Japanese Yen"]]}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let configurationStore = CurrencyMetadataServiceTestSupport.makeConfigurationStore(
            apiKey: "network-test-key"
        )
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            configurationStore: configurationStore,
            now: now
        )

        // When
        let isRefreshed = try await service.refreshIfStale(604_800)

        // Then
        let codes = try await service.fetchCodes()
        #expect(isRefreshed == scenario.shouldRefresh)
        #expect(httpClient.dataCallCount == scenario.expectedRequestCount)
        #expect(configurationStore.stringCallCount == scenario.expectedRequestCount)
        #expect(database.writeCallCount == scenario.expectedRequestCount)
        #expect(codes == scenario.expectedCodes)
    }
}

// MARK: - Nested Types

extension CurrencyMetadataServiceRefreshTests {

    /// 快取年齡的測試案例：快取經過的秒數與預期是否刷新
    struct CacheAgeCase: Sendable {

        /// 快取自上次更新後經過的秒數
        let ageInSeconds: TimeInterval

        /// 是否預期重新請求並寫入快取
        let shouldRefresh: Bool

        /// 預期的 HTTP 請求、設定讀取與資料庫寫入次數
        let expectedRequestCount: Int

        /// 刷新後預期讀到的幣別清單
        let expectedCodes: [CurrencyCode]
    }
}
