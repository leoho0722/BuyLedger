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
    
    @Test func sendBuildsRequestWithMethodHeadersBodyAndTimeout() async throws(any Error) {
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
                (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse)
                in
                throw APIError.transport(message: "unused stream")
            }
        )
        
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
        #expect(request.url == url)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == body)
        #expect(request.timeoutInterval == 12.5)
    }
    
    @Test func statusCodeOutsideSuccessRangeIsClassifiedAsHTTPError() async throws(any Error) {
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
                (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse)
                in
                throw APIError.transport(message: "unused stream")
            }
        )
        
        do {
            _ = try await client.send(url: url)
            Issue.record("Expected HTTP 300 to be rejected")
        } catch let error as APIError {
            #expect(error == .http(statusCode: 300))
        } catch {
            Issue.record("Expected an APIError, got \(error)")
        }
    }
    
    @Test func transportFailureIsForwardedWithoutReclassification() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let expected = APIError.transport(message: "network unavailable")
        let client = HTTPClient(
            data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                throw expected
            },
            stream: {
                (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse)
                in
                throw APIError.transport(message: "unused stream")
            }
        )
        
        await #expect(throws: expected) {
            try await client.send(url: url)
        }
    }
}

// MARK: - Test Doubles
/// 記錄測試收到的 HTTP request
private actor URLRequestRecorder {
    
    private var request: URLRequest?
    
    func record(_ request: URLRequest) {
        self.request = request
    }
    
    /// 回傳最近一次記錄的請求
    /// - Returns: 最近一次收到的 URL request；尚未記錄時為 `nil`
    func recordedRequest() -> URLRequest? {
        request
    }
}
