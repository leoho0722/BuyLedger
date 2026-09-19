//
//  APIErrorMappingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/07/29.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證 API 錯誤的使用者訊息
struct APIErrorMappingTests {

    // MARK: - Tests

    /// 驗證 API 錯誤分類與對應訊息
    @Test func invalidKeyResponseMapsToInvalidCredential() async throws(any Error) {
        // Given

        // When

        let actual = try await fetchServiceError(for: "invalid-key")

        // Then

        if case .invalidKey = actual {
            return
        }
        Issue.record("服務錯誤分類與預期值不符。")
    }

    /// 驗證 API 錯誤分類與對應訊息
    @Test func inactiveAccountResponseMapsToInvalidCredential() async throws(any Error) {
        // Given

        // When

        let actual = try await fetchServiceError(for: "inactive-account")

        // Then

        if case .invalidKey = actual {
            return
        }
        Issue.record("服務錯誤分類與預期值不符。")
    }

    /// 驗證 API 錯誤分類與對應訊息
    @Test func quotaReachedResponseMapsToQuotaExceeded() async throws(any Error) {
        // Given

        // When

        let actual = try await fetchServiceError(for: "quota-reached")

        // Then

        if case .quotaExceeded = actual {
            return
        }
        Issue.record("服務錯誤分類與預期值不符。")
    }

    /// 驗證 API 錯誤分類與對應訊息
    @Test func otherServiceCodeMapsToGenericServiceError() async throws(any Error) {
        // Given

        // When

        let actual = try await fetchServiceError(for: "malformed-request")

        // Then

        if case let .apiError(code) = actual {
            #expect(code == "malformed-request")
        } else {
            Issue.record("服務錯誤分類與預期值不符。")
        }
    }
}

// MARK: - Private Method

private extension APIErrorMappingTests {

    /// 以 HTTP 200 搭配服務端錯誤 payload 驅動匯率 client 的業務錯誤分流
    /// - Parameters:
    ///   - code: 服務回應代碼
    /// - Returns: client 轉換後的 API 錯誤
    /// - Throws: 測試資料建立或 client 回傳非 API 錯誤時拋出錯誤
    func fetchServiceError(for code: String) async throws(any Error) -> APIError {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(#"{"result":"error","error-type":"\#(code)"}"#.utf8)

        return try await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(message: "unused stream")
                    )
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                Issue.record("預期服務代碼 \(code) 會失敗。")
                return .apiError(code: "unexpected-success")
            } catch let error as APIError {
                return error
            } catch {
                throw error
            }
        }
    }
}
