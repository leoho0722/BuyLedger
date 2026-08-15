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

/// 驗證 API 錯誤的使用者訊息
struct APIErrorMappingTests {
    
    // MARK: - Tests
    
    @Test func invalidKeyResponseMapsToInvalidCredential() async throws(any Error) {
        try await assertServiceCode(
            "invalid-key",
            mapsTo: .invalidKey
        )
    }
    
    @Test func inactiveAccountResponseMapsToInvalidCredential() async throws(any Error) {
        try await assertServiceCode(
            "inactive-account",
            mapsTo: .invalidKey
        )
    }
    
    @Test func quotaReachedResponseMapsToQuotaExceeded() async throws(any Error) {
        try await assertServiceCode(
            "quota-reached",
            mapsTo: .quotaExceeded
        )
    }
    
    @Test func otherServiceCodeMapsToGenericServiceError() async throws(any Error) {
        try await assertServiceCode(
            "malformed-request",
            mapsTo: .apiError(code: "malformed-request")
        )
    }
}

// MARK: - Private Method

private extension APIErrorMappingTests {
    
    /// 以 HTTP 200 搭配服務端錯誤 payload 驅動匯率 client 的業務錯誤分流
    /// - Parameters:
    ///   - code: 服務回應代碼
    ///   - expected: 預期的錯誤
    /// - Throws: 測試資料建立或 API 錯誤驗證失敗時拋出錯誤
    func assertServiceCode(_ code: String, mapsTo expected: APIError) async throws(any Error) {
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
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: { (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                Issue.record("Expected service code \(code) to fail")
            } catch let error as APIError {
                #expect(error == expected)
            } catch {
                Issue.record("Expected an APIError, got \(error)")
            }
        }
    }
}
