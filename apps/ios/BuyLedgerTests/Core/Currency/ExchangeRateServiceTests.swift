//
//  ExchangeRateServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `ExchangeRateService` 的單元測試，涵蓋請求組裝與回應解碼
struct ExchangeRateServiceTests {

    /// 驗證金鑰含控制字元時，請求在送出前就被拒絕，底層錯誤為 `com.leoho.BuyLedger.networking` 網域的 URL 組合失敗，且不發出請求
    ///
    /// - Throws: 沒有取得預期的傳輸錯誤時丟出測試斷言錯誤
    @Test
    func fetchLatest_金鑰含控制字元_送出前拒絕且不洩漏憑證() async throws {
        // Given
        let fakeKey = "network-test-fake-key\u{0000}"
        let httpClient = MockHTTPClient()
        let service = Self.makeService(httpClient: httpClient, apiKey: fakeKey)
        var actualError: APIError?

        // When
        do {
            _ = try await service.fetchLatest(.usd)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let underlying: (any Error & Sendable)?
        switch error {
        case .transport(let actualUnderlying):
            underlying = actualUnderlying

        case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
            underlying = nil
        }
        let diagnosticError = try #require(underlying) as NSError
        #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
        #expect(diagnosticError.code == 1)
        #expect(diagnosticError.localizedDescription == "URL 組合失敗。")
        #expect(httpClient.dataCallCount == 0)
        #expect(httpClient.dataReceivedArguments.isEmpty)
    }

    /// 驗證缺少 API key 時回報無效憑證，且不送出請求
    ///
    /// - Throws: Service 未丟出錯誤時由 `try #require` 丟出測試斷言錯誤
    @Test
    func fetchLatest_缺少金鑰_回報無效憑證() async throws {
        // Given
        let httpClient = MockHTTPClient()
        let service = Self.makeService(httpClient: httpClient, apiKey: nil)
        var actualError: APIError?

        // When
        do {
            _ = try await service.fetchLatest(.usd)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isInvalidKey: Bool
        switch error {
        case .invalidKey:
            isInvalidKey = true

        case .transport, .http, .decoding, .apiError, .quotaExceeded:
            isInvalidKey = false
        }
        #expect(isInvalidKey)
        #expect(httpClient.dataCallCount == 0)
    }

    /// 驗證成功請求以 Bearer 形式把金鑰放進 Authorization header，且請求網址不含金鑰
    ///
    /// - Throws: 連線、回應或服務端驗證失敗時丟出 API 錯誤；無法建立回應資料或沒有記錄請求網址時丟出測試斷言錯誤
    @Test
    func fetchLatest_成功請求_金鑰只放授權標頭() async throws {
        // Given
        let key = "unit-test-live-key"
        let responseJSON = #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","conversion_rates":{"TWD":32.5}}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: key)

        // When
        _ = try await service.fetchLatest(.usd)

        // Then
        let request = try #require(httpClient.dataReceivedArguments.first)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/latest/USD")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }

    /// 驗證成功回應時，快照以回應的更新時間為日期、以回應的基準幣別為基準，並收錄全部匯率
    ///
    /// - Throws: 連線、回應或服務端驗證失敗時丟出 API 錯誤；無法建立回應資料時丟出測試斷言錯誤
    @Test
    func fetchLatest_成功回應_解碼完整匯率快照() async throws {
        // Given
        let responseJSON = #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","conversion_rates":{"TWD":32.5,"JPY":150.0}}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")

        // When
        let snapshot = try await service.fetchLatest(.usd)

        // Then
        #expect(snapshot.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(snapshot.base == .usd)
        #expect(snapshot.rates == [.twd: Decimal(32.5), .jpy: Decimal(150)])
    }

    /// 驗證缺少必要回應欄位時分類為解碼錯誤，底層錯誤網域為 `NSCocoaErrorDomain`，且只送出一次請求
    ///
    /// - Throws: 未取得預期的解碼錯誤或無法建立回應資料時丟出測試斷言錯誤
    @Test
    func fetchLatest_缺少必要欄位_分類為解碼錯誤() async throws {
        // Given
        let malformedBody = Data(#"{"conversion_rates":{}}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: malformedBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")
        var actualError: APIError?

        // When
        do {
            _ = try await service.fetchLatest(.usd)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let underlying: (any Error & Sendable)?
        switch error {
        case .decoding(let actualUnderlying):
            underlying = actualUnderlying

        case .transport, .http, .apiError, .quotaExceeded, .invalidKey:
            underlying = nil
        }
        let decodingError = try #require(underlying) as NSError
        #expect(decodingError.domain == NSCocoaErrorDomain)
        #expect(httpClient.dataCallCount == 1)
    }

    /// 驗證無法辨識的回應結果值歸類為 `.apiError`，錯誤碼保留原始結果字串，且只送出一次請求
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；Service 未丟出錯誤時由 `try #require`
    ///   丟出測試斷言錯誤
    @Test
    func fetchLatest_未知結果_分類為服務錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"partial"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTestSupport.makeHTTPResponse(body: responseBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")
        var actualError: APIError?

        // When
        do {
            _ = try await service.fetchLatest(.usd)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualCode: String?
        switch error {
        case .apiError(let code):
            actualCode = code

        case .transport, .http, .decoding, .quotaExceeded, .invalidKey:
            actualCode = nil
        }
        #expect(actualCode == "unexpected-result-partial")
        #expect(httpClient.dataCallCount == 1)
    }
}

// MARK: - Private Method

private extension ExchangeRateServiceTests {

    /// 以指定 HTTP client 與 API key 建立正式 Service，並注入固定時間
    ///
    /// - Parameters:
    ///   - httpClient: 要注入的 HTTP client
    ///   - apiKey: 要提供給 Service 的 API key
    /// - Returns: 已擷取測試依賴的正式 Service
    static func makeService(httpClient: MockHTTPClient, apiKey: String?) -> ExchangeRateService {
        let configurationStore = CurrencyMetadataServiceTestSupport.makeConfigurationStore(
            apiKey: apiKey
        )
        return withDependencies {
            $0.httpClient = httpClient
            $0.appConfigurationStore = configurationStore
            $0.date = .constant(TestDependencies.fixedNow)
        } operation: {
            ExchangeRateService.liveValue
        }
    }
}
