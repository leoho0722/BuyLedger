//
//  CurrencyMetadataServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CurrencyMetadataService` 的單元測試，涵蓋 API 錯誤分類與快取行為
struct CurrencyMetadataServiceTests {

    /// 驗證金鑰含控制字元時，請求在送出前就被拒絕，底層錯誤為 `com.leoho.BuyLedger.networking` 網域的 URL 組合失敗，且不發出請求
    ///
    /// - Throws: 沒有取得預期的 API 傳輸錯誤時丟出測試斷言錯誤
    @Test
    func refreshIfStale_金鑰含控制字元_送出前拒絕且不洩漏憑證() async throws {
        // Given
        let httpClient = MockHTTPClient()
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-fake-key\u{0000}",
            now: TestDependencies.fixedNow
        )
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
        let diagnosticError = try #require(underlying) as NSError
        #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
        #expect(diagnosticError.code == 1)
        #expect(diagnosticError.localizedDescription == "URL 組合失敗。")
        #expect(httpClient.dataCallCount == 0)
        #expect(httpClient.dataReceivedArguments.isEmpty)
    }

    /// 驗證成功取得支援幣別時，金鑰只放在 Authorization header，請求網址不含金鑰
    ///
    /// - Throws: 連線、回應或服務端驗證失敗時丟出 API 錯誤；快取讀取、寫入或清單為空時丟出持久化錯誤；回應資料或請求不符時丟出測試斷言錯誤
    @Test
    func refreshIfStale_成功請求_金鑰只放授權標頭() async throws {
        // Given
        let key = "unit-test-live-key-codes"
        let responseJSON = #"{"result":"success","supported_codes":[["USD","US Dollar"]]}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: key,
            now: TestDependencies.fixedNow
        )

        // When
        let isRefreshed = try await service.refreshIfStale(0)

        // Then
        let codes = try await service.fetchCodes()
        #expect(isRefreshed)
        #expect(codes == [.usd])
        let request = try #require(httpClient.dataReceivedArguments.first)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/codes")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }

    /// 驗證 API 回報配額用盡時歸類為 `.quotaExceeded`，且只送出一次請求
    ///
    /// - Throws: `refreshIfStale` 沒有丟出錯誤，或 fixture 建立失敗時由 `#require` 丟出
    ///   測試斷言錯誤
    @Test
    func refreshIfStale_配額耗盡回應_歸類為配額錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"error","error-type":"quota-reached"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase(),
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: TestDependencies.fixedNow
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isQuotaExceeded: Bool
        switch error {
        case .api(.quotaExceeded):
            isQuotaExceeded = true

        case .api(.transport), .api(.http), .api(.decoding), .api(.apiError), .api(.invalidKey),
                .persistence:
            isQuotaExceeded = false
        }
        #expect(isQuotaExceeded)
        #expect(httpClient.dataCallCount == 1)
    }

    /// 驗證無法辨識的回應結果值歸類為 `.apiError`，錯誤碼保留原始結果字串，且只送出一次請求
    ///
    /// - Throws: `refreshIfStale` 沒有丟出錯誤，或 fixture 建立失敗時由 `#require` 丟出
    ///   測試斷言錯誤
    @Test
    func refreshIfStale_未知結果_分類為服務錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"partial"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = CurrencyMetadataServiceTestSupport.makeService(
            database: BuyLedgerDatabaseTestSupport.makeInMemoryDatabase(),
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: TestDependencies.fixedNow
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do {
            _ = try await service.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualCode: String?
        switch error {
        case .api(.apiError(let code)):
            actualCode = code

        case .api(.transport), .api(.http), .api(.decoding), .api(.quotaExceeded),
                .api(.invalidKey), .persistence:
            actualCode = nil
        }
        #expect(actualCode == "unexpected-result-partial")
        #expect(httpClient.dataCallCount == 1)
    }
}
