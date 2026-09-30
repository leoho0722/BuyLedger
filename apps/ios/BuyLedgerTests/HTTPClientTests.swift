//
//  HTTPClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證 HTTP client 的請求與錯誤處理
struct HTTPClientTests {

    // MARK: - Tests

    /// 驗證 HTTP client 保留請求 `URL`、方法、標頭、內容與逾時
    ///
    /// - Throws: 測試前置條件或請求檢查未通過時，由 `#require` 丟出測試失敗；
    ///   傳輸失敗時丟出 `.transport(underlying:)`，狀態碼不在 200 至 299 時丟出 `.http(statusCode:)`
    @Test
    func send_自訂方法標頭本文與逾時_完整建立請求() async throws {
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
        let client = MockHTTPClient()
        client.dataResult = .success((Data(), response))

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

        // Then
        let request = try #require(client.dataReceivedArguments.first)
        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == body)
        #expect(request.timeoutInterval == 12.5)
    }

    /// 驗證非 2xx 狀態碼會分類為 `APIError.http`
    ///
    /// - Throws: 測試 URL、`HTTPURLResponse` 建立失敗，或預期的 HTTP 錯誤 case 未出現時，
    ///   由 `#require` 丟出測試失敗
    @Test
    func send_回應狀態非二百至二九九_分類為狀態碼錯誤() async throws {
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
        let client = MockHTTPClient()
        client.dataResult = .success((Data("response".utf8), response))
        var actualError: APIError?

        // When
        do throws(APIError) {
            _ = try await client.send(url: url)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let receivedStatusCode: Int?
        switch error {
        case .http(let statusCode):
            receivedStatusCode = statusCode

        case .transport, .decoding, .apiError, .quotaExceeded, .invalidKey:
            receivedStatusCode = nil
        }
        let statusCode = try #require(receivedStatusCode)
        #expect(statusCode == 300)
    }

    /// `data(for:)` 丟出的 `.transport(underlying:)` 經 `send` 原樣轉送，底層錯誤的 `domain`、`code` 與說明都不變
    ///
    /// - Throws: 測試 URL 建立失敗，或預期的錯誤 case／底層資訊未出現時，
    ///   由 `#require` 丟出測試失敗
    @Test
    func send_傳輸發生錯誤_原樣轉送錯誤() async throws {
        // Given
        let url = try #require(URL(string: "https://example.com/resource"))
        let expectedUnderlying = NSError(
            domain: "com.leoho.BuyLedger.http-client-test",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: "network unavailable"]
        )
        let client = MockHTTPClient()
        client.dataResult = .failure(.transport(underlying: expectedUnderlying))
        var actualError: APIError?

        // When
        do throws(APIError) {
            _ = try await client.send(url: url)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let receivedUnderlying: (any Error & Sendable)?
        switch error {
        case .transport(let underlying):
            receivedUnderlying = underlying

        case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
            receivedUnderlying = nil
        }
        let underlying = try #require(receivedUnderlying)
        let actualUnderlying = underlying as NSError
        #expect(actualUnderlying.domain == expectedUnderlying.domain)
        #expect(actualUnderlying.code == expectedUnderlying.code)
        #expect(actualUnderlying.localizedDescription == expectedUnderlying.localizedDescription)
    }

    /// 驗證串流請求保留方法、標頭、本文與逾時
    ///
    /// - Throws: 建立測試 URL 失敗、串流沒有丟出任何錯誤，或 `bytes(for:)` 沒有收到請求時，由 `#require` 丟出
    @Test
    func stream_自訂方法標頭本文與逾時_完整建立請求() async throws {
        // Given
        let url = try #require(URL(string: "https://example.com/stream"))
        let body = Data("stream-request-body".utf8)
        let client = MockHTTPClient()
        var actualError: APIError?

        // When
        do throws(APIError) {
            _ = try await client.stream(
                url: url,
                method: .post,
                headers: [
                    "Authorization": "Bearer stream-test-token",
                    "Content-Type": "application/x-ndjson",
                ],
                body: body,
                timeout: 12.5
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let receivedUnderlying: (any Error & Sendable)?
        switch error {
        case .transport(let underlying):
            receivedUnderlying = underlying

        case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
            receivedUnderlying = nil
        }
        #expect(receivedUnderlying != nil)
        #expect(client.bytesCallCount == 1)
        let request = try #require(client.bytesReceivedArguments.first)
        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer stream-test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-ndjson")
        #expect(request.httpBody == body)
        #expect(request.timeoutInterval == 12.5)
    }

    /// 驗證串流回應非 2xx 時分類為 `APIError.http`
    ///
    /// - Throws: 建立測試 URL 失敗或串流沒有丟出任何錯誤時，由 `#require` 丟出
    @Test
    func stream_回應狀態非二百至二九九_分類為狀態碼錯誤() async throws {
        // Given
        let url = try #require(URL(string: "https://example.com/non-success-stream"))
        let authorization = "Bearer http-client-status-test"
        MockURLProtocol.setStub(
            authorization: authorization,
            statusCode: 503,
            body: Data("unavailable".utf8)
        )
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let client = HTTPClient(session: URLSession(configuration: configuration))
        var actualError: APIError?

        // When
        do throws(APIError) {
            _ = try await client.stream(url: url, headers: ["Authorization": authorization])
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let receivedStatusCode: Int?
        switch error {
        case .http(let statusCode):
            receivedStatusCode = statusCode

        case .transport, .decoding, .apiError, .quotaExceeded, .invalidKey:
            receivedStatusCode = nil
        }
        #expect(receivedStatusCode == 503)
    }
}
