//
//  APIErrorMappingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證匯率 Service 把服務端錯誤代碼轉成 `APIError`
struct APIErrorMappingTests {

    // MARK: - Tests

    /// 無效金鑰或停用帳號代碼都轉換為無效金鑰錯誤
    ///
    /// - Parameter errorCode: 服務回應中的錯誤代碼
    /// - Throws: `fetchLatest` 沒有丟出任何錯誤，或建立測試 HTTP 回應失敗時由 `#require` 丟出
    @Test(arguments: ["invalid-key", "inactive-account"])
    func fetchLatest_無效憑證或帳號停用_丟出無效金鑰錯誤(errorCode: String) async throws {
        // Given
        let service = try Self.makeService(errorCode: errorCode)
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
    }

    /// 配額用盡代碼轉換為配額錯誤
    ///
    /// - Throws: `fetchLatest` 沒有丟出任何錯誤，或建立測試 HTTP 回應失敗時由 `#require` 丟出
    @Test
    func fetchLatest_配額用盡回應_丟出配額錯誤() async throws {
        // Given
        let service = try Self.makeService(errorCode: "quota-reached")
        var actualError: APIError?

        // When
        do throws(APIError) {
            _ = try await service.fetchLatest(.usd)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let isQuotaExceeded: Bool
        switch error {
        case .quotaExceeded:
            isQuotaExceeded = true

        case .transport, .http, .decoding, .apiError, .invalidKey:
            isQuotaExceeded = false
        }
        #expect(isQuotaExceeded)
    }

    /// 未知服務錯誤代碼保留原始代碼供上層處理
    ///
    /// - Throws: `fetchLatest` 沒有丟出任何錯誤，或建立測試 HTTP 回應失敗時由 `#require` 丟出
    @Test
    func fetchLatest_其他服務錯誤代碼_保留原始代碼() async throws {
        // Given
        let service = try Self.makeService(errorCode: "malformed-request")
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
        #expect(actualCode == "malformed-request")
    }
}

// MARK: - Private Method

private extension APIErrorMappingTests {

    /// 建立注入 HTTP 200 服務錯誤回應的 `ExchangeRateService`
    ///
    /// - Parameter errorCode: 服務回應中的錯誤代碼
    /// - Returns: 使用測試 HTTP 回應與 API 金鑰的正式 Service
    /// - Throws: 建立測試 HTTP 回應失敗時拋出錯誤
    static func makeService(errorCode: String) throws -> ExchangeRateService {
        let responseBody = Data(#"{"result":"error","error-type":"\#(errorCode)"}"#.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(
            try CurrencyMetadataServiceTests.makeHTTPResponse(body: responseBody)
        )
        let configurationStore = CurrencyMetadataServiceTests.makeConfigurationStore(
            apiKey: "network-test-key"
        )
        return withDependencies {
            $0.httpClient = httpClient
            $0.appConfigurationStore = configurationStore
        } operation: {
            ExchangeRateService.liveValue
        }
    }
}
