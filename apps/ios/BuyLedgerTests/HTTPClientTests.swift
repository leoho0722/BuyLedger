//
//  HTTPClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/07/29.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證 HTTP client 的請求與錯誤處理
struct HTTPClientTests {

    // MARK: - Tests

    /// 驗證 HTTP client 在此情境下的請求與錯誤
    @Test func sendBuildsRequestWithMethodHeadersBodyAndTimeout() async throws(any Error) {
        // Given

        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data("request-body".utf8)
        let recorder = URLRequestRecorder()
        let client = HTTPClient(
            data: { request in
                await recorder.record(request)
                return (Data(), response)
            },
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

        // When

        _ = try await client.send(
            url: url,
            method: .post,
            headers: [
                "Authorization": "Bearer test-token",
                "Content-Type": "application/json",
            ],
            body: body,
            timeout: 12.5
        )

        let request = try #require(await recorder.recordedRequest())
        // Then

        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == body)
        #expect(request.timeoutInterval == 12.5)
    }

    /// 驗證 HTTP client 在此情境下的請求與錯誤
    @Test func statusCodeOutsideSuccessRangeIsClassifiedAsHTTPError() async throws(any Error) {
        // Given

        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 300,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let client = HTTPClient(
            data: { _ in (Data("response".utf8), response) },
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

        do {
            // When

            _ = try await client.send(url: url)
            // Then

            Issue.record("預期 HTTP 300 會被拒絕。")
        } catch {
            switch error {
            case let .http(statusCode):
                #expect(statusCode == 300)
            case .transport, .decoding, .apiError, .quotaExceeded, .invalidKey:
                Issue.record("預期為 HTTP 狀態錯誤，實際為其他 API 錯誤。")
            }
        }
    }

    /// 驗證 HTTP client 在此情境下的請求與錯誤
    @Test func transportFailureIsForwardedWithoutReclassification() async throws(any Error) {
        // Given

        let url = try #require(URL(string: "https://example.com/resource"))
        let expectedUnderlying = NSError(
            domain: "com.leoho.BuyLedger.http-client-test",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: "network unavailable"]
        )
        let client = HTTPClient(
            data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                throw APIError.transport(underlying: expectedUnderlying)
            },
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

        do {
            // When

            _ = try await client.send(url: url)
            // Then

            Issue.record("預期會拋出 transport 錯誤。")
        } catch {
            switch error {
            case let .transport(underlying):
                let actualUnderlying = underlying as NSError
                #expect(actualUnderlying.domain == expectedUnderlying.domain)
                #expect(actualUnderlying.code == expectedUnderlying.code)
                #expect(
                    actualUnderlying.localizedDescription == expectedUnderlying.localizedDescription
                )
            case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
                Issue.record("預期為帶 NSError 底層錯誤的 API transport 錯誤。")
            }
        }
    }

    /// 未注入 HTTP client 依賴時應使用自有診斷分類
    @Test func unconfiguredHTTPClientUsesDependencyDiagnostic() async throws(any Error) {
        // Given

        let url = try #require(URL(string: "https://example.com/resource"))
        let request = URLRequest(url: url)

        // When

        do {
            _ = try await HTTPClient.testValue.data(request)
            // Then

            Issue.record("未注入的 HTTP client 應拋出 transport 錯誤。")
        } catch {
            switch error {
            case let .transport(underlying):
                let diagnosticError = underlying as NSError
                #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
                #expect(diagnosticError.code == 2)
            case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
                Issue.record("預期為未注入依賴的 transport 錯誤。")
            }
        }
    }
}

// MARK: - Test Doubles
/// 記錄測試收到的 HTTP request
private actor URLRequestRecorder {

    /// 最近一次收到的 HTTP request
    private var request: URLRequest?

    /// 記錄收到的 HTTP request
    /// - Parameter request: 收到的 HTTP request
    func record(_ request: URLRequest) {
        self.request = request
    }

    /// 回傳最近一次記錄的請求
    /// - Returns: 最近一次收到的 URL request；尚未記錄時為 `nil`
    func recordedRequest() -> URLRequest? {
        request
    }
}
