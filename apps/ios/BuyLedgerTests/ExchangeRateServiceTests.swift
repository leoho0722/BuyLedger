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

/// 驗證匯率 Service 的請求與回應處理
struct ExchangeRateServiceTests {

    // MARK: - Tests

    /// 金鑰含控制字元時不送出請求，並保留不含憑證的診斷錯誤
    ///
    /// - Throws: 沒有取得預期的 `.transport(underlying:)` 時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchLatest_金鑰含控制字元_送出前拒絕且不洩漏憑證() async throws {
        // Given
        let fakeKey = "network-test-fake-key\u{0000}"
        let httpClient = MockHTTPClient()
        let service = Self.makeService(httpClient: httpClient, apiKey: fakeKey)
        var actualError: APIError?

        // When
        do throws(APIError) {
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

    /// 缺少 API key 時回報無效憑證且不送出請求
    ///
    /// - Throws: Service 未拋出錯誤時由 `try #require` 丟出測試斷言錯誤
    @Test
    func fetchLatest_缺少金鑰_回報無效憑證() async throws {
        // Given
        let httpClient = MockHTTPClient()
        let service = Self.makeService(httpClient: httpClient, apiKey: nil)
        var actualError: APIError?

        // When
        do throws(APIError) {
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

    /// 成功請求只以 Bearer 形式將金鑰放進 Authorization header，且請求網址不含金鑰
    ///
    /// - Throws: Service 失敗時丟出 `.invalidKey`、`.transport(underlying:)`、`.http(statusCode:)`、
    ///   `.decoding(underlying:)`、`.quotaExceeded` 或 `.apiError(code:)`；response fixture 建立
    ///   失敗時由 `try #require` 丟出測試斷言錯誤；沒有記錄送出的請求或請求沒有網址時，
    ///   也由 `try #require` 丟出測試斷言錯誤
    @Test
    func fetchLatest_成功請求_金鑰只放授權標頭() async throws {
        // Given
        let key = "unit-test-live-key"
        let responseJSON = #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","conversion_rates":{"TWD":32.5}}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTests.makeHTTPResponse(body: responseBody)
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

    /// 成功回應時依 API 時間、基準幣別與所有匯率建立快照
    ///
    /// - Throws: Service 失敗時丟出 `.invalidKey`、`.transport(underlying:)`、`.http(statusCode:)`、
    ///   `.decoding(underlying:)`、`.quotaExceeded` 或 `.apiError(code:)`；HTTP response fixture
    ///   建立失敗時由 `#require` 丟出測試斷言錯誤
    @Test
    func fetchLatest_成功回應_解碼完整匯率快照() async throws {
        // Given
        let responseJSON = #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","conversion_rates":{"TWD":32.5,"JPY":150.0}}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTests.makeHTTPResponse(body: responseBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")

        // When
        let snapshot = try await service.fetchLatest(.usd)

        // Then
        #expect(snapshot.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(snapshot.base == .usd)
        #expect(snapshot.rates == [.twd: Decimal(32.5), .jpy: Decimal(150)])
    }

    /// 缺少必要回應欄位時分類為解碼錯誤，保留底層錯誤網域且只送出一次請求
    ///
    /// - Throws: 未取得預期 `.decoding(underlying:)` 或 fixture 建立失敗時由 `#require` 丟出
    ///   測試斷言錯誤
    @Test
    func fetchLatest_缺少必要欄位_分類為解碼錯誤() async throws {
        // Given
        let malformedBody = Data(#"{"conversion_rates":{}}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTests.makeHTTPResponse(body: malformedBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")
        var actualError: APIError?

        // When
        do throws(APIError) {
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

    /// 無法辨識的服務結果會保留原始結果字串
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；Service 未拋出錯誤時由 `try #require`
    ///   丟出測試斷言錯誤
    @Test
    func fetchLatest_未知結果_分類為服務錯誤() async throws {
        // Given
        let responseBody = Data(#"{"result":"partial"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTests.makeHTTPResponse(body: responseBody)
        )
        let service = Self.makeService(httpClient: httpClient, apiKey: "network-test-key")
        var actualError: APIError?

        // When
        do throws(APIError) {
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
        let configurationStore = CurrencyMetadataServiceTests.makeConfigurationStore(apiKey: apiKey)
        return withDependencies {
            $0.httpClient = httpClient
            $0.appConfigurationStore = configurationStore
            $0.date = .constant(TestDependencies.fixedNow)
        } operation: {
            ExchangeRateService.liveValue
        }
    }
}
