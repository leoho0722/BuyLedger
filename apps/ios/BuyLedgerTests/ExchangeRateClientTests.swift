//
//  ExchangeRateClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證匯率 client
struct ExchangeRateClientTests {
    
    // MARK: - Tests
    
    @Test func latestControlCharacterKeyIsRejectedBeforeURLParsingWithoutExposingCredentials() async {
        let fakeKey = "network-test-fake-key\u{0000}"
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { fakeKey },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                    throw APIError.transport(message: "unexpected HTTP call")
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unexpected HTTP call")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                Issue.record("Expected the control-character key to be rejected before URL parsing")
            } catch let APIError.transport(message) {
                #expect(message == "URL 組合失敗。")
            } catch {
                Issue.record("Expected a transport error, got \(error)")
            }
        }
    }
    
    @Test
    func supportedCodesControlCharacterKeyIsRejectedBeforeURLParsingWithoutExposingCredentials() async {
        let fakeKey = "network-test-supported-codes-key\u{0000}"
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { fakeKey },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                    throw APIError.transport(message: "unexpected HTTP call")
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unexpected HTTP call")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                Issue.record("Expected the control-character key to be rejected before URL parsing")
            } catch let APIError.transport(message) {
                #expect(message == "URL 組合失敗。")
            } catch {
                Issue.record("Expected a transport error, got \(error)")
            }
        }
    }
    
    @Test func latestRequestCarriesBearerHeaderAndURLContainsNoCredential() async throws(any Error) {
        let key = "unit-test-live-key"
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(
            (
                #"{"result":"success","time_last_update_unix":1700000000,"#
                    + #"base_code":"USD","conversion_rates":{"TWD":"#
                    + #"32.5}}"#
            ).utf8
        )
        let capturedRequest = RequestCaptureBox()
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { key },
                ollamaAPIKey: { nil }
            )
            $0.date = .constant(TestDependencies.fixedNow)
            $0.httpClient = HTTPClient(
                data: { request in
                    capturedRequest.request = request
                    return (body, response)
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
            } catch {
                Issue.record("Expected the latest-rate request to succeed, got \(error)")
            }
        }
        
        let request = try #require(capturedRequest.request)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/latest/USD")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }
    
    @Test func supportedCodesRequestCarriesBearerHeaderAndURLContainsNoCredential() async throws(any Error) {
        let key = "unit-test-live-key-codes"
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(#"{"result":"success","supported_codes":[["USD","US Dollar"]]}"#.utf8)
        let capturedRequest = RequestCaptureBox()
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { key },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { request in
                    capturedRequest.request = request
                    return (body, response)
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
            } catch {
                Issue.record("Expected the supported-codes request to succeed, got \(error)")
            }
        }
        
        let request = try #require(capturedRequest.request)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/codes")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }
    
    @Test func successfulLatestResponseDecodesIntoSnapshot() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(
            (
                #"{"result":"success","time_last_update_unix":1700000000,"#
                    + #"base_code":"USD","conversion_rates":{"TWD":32.5,"#
                    + #"JPY":150.0}}"#
            ).utf8
        )
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.date = .constant(TestDependencies.fixedNow)
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                let snapshot = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                #expect(snapshot.date == Date(timeIntervalSince1970: 1_700_000_000))
                #expect(snapshot.base == .usd)
                #expect(
                    snapshot.rates == [
                        .twd: Decimal(32.5),
                        .jpy: Decimal(150),
                    ])
            } catch {
                Issue.record("Expected a decoded snapshot, got \(error)")
            }
        }
    }
    
    @Test func malformedLatestResponseIsClassifiedAsDecodingFailure() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let malformedBody = Data(
            #"{"result":"success","conversion_rates":"not-a-map"}"#.utf8
        )
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (malformedBody, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                Issue.record("Expected malformed response to fail decoding")
            } catch let APIError.decoding(message) {
                #expect(!message.isEmpty)
            } catch {
                Issue.record("Expected a decoding error, got \(error)")
            }
        }
    }
    
    @Test func supportedCodesQuotaResponseUsesSharedServiceErrorMapping() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(#"{"result":"error","error-type":"quota-reached"}"#.utf8)
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                Issue.record("Expected supported-codes quota response to fail")
            } catch let error as APIError {
                #expect(error == .quotaExceeded)
            } catch {
                Issue.record("Expected an APIError, got \(error)")
            }
        }
    }
    
    @Test func unexpectedLatestResultMapsToGenericServiceError() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(#"{"result":"partial"}"#.utf8)
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                Issue.record("Expected an unexpected result to fail")
            } catch let error as APIError {
                #expect(error == .apiError(code: "unexpected-result-partial"))
            } catch {
                Issue.record("Expected an APIError, got \(error)")
            }
        }
    }
    
    @Test func unexpectedSupportedCodesResultMapsToGenericServiceError() async throws(any Error) {
        let url = try #require(URL(string: "https://example.com/resource"))
        let response = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let body = Data(#"{"result":"partial"}"#.utf8)
        
        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (body, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes, HTTPURLResponse
                    ) in
                    throw APIError.transport(message: "unused stream")
                }
            )
        } operation: {
            do {
                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                Issue.record("Expected an unexpected result to fail")
            } catch let error as APIError {
                #expect(error == .apiError(code: "unexpected-result-partial"))
            } catch {
                Issue.record("Expected an APIError, got \(error)")
            }
        }
    }
}

/// 捕捉 httpClient 收到的 URLRequest
private final class RequestCaptureBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 由 `data` closure 寫入、測試讀取的請求
    var request: URLRequest?
}
