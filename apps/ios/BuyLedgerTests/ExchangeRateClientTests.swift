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

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test
    func latestControlCharacterKeyIsRejectedBeforeURLParsingWithoutExposingCredentials() async {
        // Given

        let fakeKey = "network-test-fake-key\u{0000}"

        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { fakeKey },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unexpected HTTP call"
                        )
                    )
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unexpected HTTP call"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                // Then

                Issue.record("預期含控制字元的 key 會在 URL 解析前被拒絕。")
            } catch let error as APIError {
                guard case let .transport(underlying) = error else {
                    Issue.record("預期為 transport 錯誤，實際為 \(error)。")
                    return
                }
                let diagnosticError = underlying as NSError
                #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
                #expect(diagnosticError.code == 1)
                #expect(underlying.localizedDescription == "URL 組合失敗。")
            } catch {
                Issue.record("預期為 transport 錯誤，實際為 \(error)。")
            }
        }
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test
    func supportedCodesControlCharacterKeyIsRejectedBeforeURLParsingWithoutExposingCredentials()
        async {
        // Given

        let fakeKey = "network-test-supported-codes-key\u{0000}"

        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { fakeKey },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unexpected HTTP call"
                        )
                    )
                },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unexpected HTTP call"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                // Then

                Issue.record("預期含控制字元的 key 會在 URL 解析前被拒絕。")
            } catch let error as APIError {
                guard case let .transport(underlying) = error else {
                    Issue.record("預期為 transport 錯誤，實際為 \(error)。")
                    return
                }
                let diagnosticError = underlying as NSError
                #expect(diagnosticError.domain == "com.leoho.BuyLedger.networking")
                #expect(diagnosticError.code == 1)
                #expect(underlying.localizedDescription == "URL 組合失敗。")
            } catch {
                Issue.record("預期為 transport 錯誤，實際為 \(error)。")
            }
        }
    }

    /// 未注入匯率 client 依賴時應保留自有診斷分類
    @Test func unconfiguredExchangeRateClientUsesDependencyDiagnostic() async {
        // Given

        // When

        do {
            _ = try await ExchangeRateClient.testValue.fetchLatest(.usd)
            // Then

            Issue.record("未注入的匯率 client 應拋出 transport 錯誤。")
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

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test
    func latestRequestCarriesBearerHeaderAndURLContainsNoCredential() async throws(any Error) {
        // Given

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
                #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","#
                + #""conversion_rates":{"TWD":32.5}}"#
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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
            } catch {
                // Then

                Issue.record("預期最新匯率請求成功，實際為 \(error)。")
            }
        }

        let request = try #require(capturedRequest.request)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/latest/USD")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test
    func supportedCodesRequestCarriesBearerHeaderAndURLContainsNoCredential()
        async throws(any Error) {
        // Given

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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
            } catch {
                // Then

                Issue.record("預期支援幣別請求成功，實際為 \(error)。")
            }
        }

        let request = try #require(capturedRequest.request)
        let requestURLString = try #require(request.url?.absoluteString)
        #expect(requestURLString == "https://v6.exchangerate-api.com/v6/codes")
        #expect(!requestURLString.contains(key))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(key)")
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test func successfulLatestResponseDecodesIntoSnapshot() async throws(any Error) {
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
        let body = Data(
            (
                #"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","#
                + #""conversion_rates":{"TWD":32.5,"JPY":150.0}}"#
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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                let snapshot = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                // Then

                #expect(snapshot.date == Date(timeIntervalSince1970: 1_700_000_000))
                #expect(snapshot.base == .usd)
                #expect(
                    snapshot.rates == [
                        .twd: Decimal(32.5),
                        .jpy: Decimal(150),
                    ])
            } catch {
                Issue.record("預期成功解碼匯率快照，實際為 \(error)。")
            }
        }
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test func missingRequiredFieldIsClassifiedAsDecodingFailure() async throws(any Error) {
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
        let malformedBody = Data(#"{"conversion_rates":{}}"#.utf8)

        await withDependencies {
            $0.appConfiguration = AppConfiguration(
                exchangeRateAPIKey: { "network-test-key" },
                ollamaAPIKey: { nil }
            )
            $0.httpClient = HTTPClient(
                data: { _ in (malformedBody, response) },
                stream: {
                    (_: URLRequest) async throws(APIError) -> (
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                // Then

                Issue.record("預期格式錯誤的回應會解碼失敗。")
            } catch let error as APIError {
                guard case let .decoding(underlying) = error else {
                    Issue.record("預期為 decoding 錯誤，實際為 \(error)。")
                    return
                }
                let decodingError = underlying as NSError
                #expect(decodingError.domain == NSCocoaErrorDomain)
            } catch {
                Issue.record("預期為 decoding 錯誤，實際為 \(error)。")
            }
        }
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test func supportedCodesQuotaResponseUsesSharedServiceErrorMapping() async throws(any Error) {
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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                // Then

                Issue.record("預期支援幣別的配額回應會失敗。")
            } catch let error as APIError {
                guard case .quotaExceeded = error else {
                    Issue.record("預期為配額耗盡錯誤，實際為 \(error)。")
                    return
                }
            } catch {
                Issue.record("預期為 APIError，實際為 \(error)。")
            }
        }
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test func unexpectedLatestResultMapsToGenericServiceError() async throws(any Error) {
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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchLatest(.usd)
                // Then

                Issue.record("預期非預期的結果會失敗。")
            } catch let error as APIError {
                guard case let .apiError(code) = error else {
                    Issue.record("預期為服務 API 錯誤，實際為 \(error)。")
                    return
                }
                #expect(code == "unexpected-result-partial")
            } catch {
                Issue.record("預期為 APIError，實際為 \(error)。")
            }
        }
    }

    /// 驗證匯率 client 在此情境下的請求與結果
    @Test func unexpectedSupportedCodesResultMapsToGenericServiceError() async throws(any Error) {
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
                        URLSession.AsyncBytes,
                        HTTPURLResponse
                    ) in
                    throw APIError.transport(
                        underlying: TestDependencies.makeUnderlyingError(
                            message: "unused stream"
                        )
                    )
                }
            )
        } operation: {
            do {
                // When

                _ = try await ExchangeRateClient.liveValue.fetchSupportedCodes()
                // Then

                Issue.record("預期非預期的結果會失敗。")
            } catch let error as APIError {
                guard case let .apiError(code) = error else {
                    Issue.record("預期為服務 API 錯誤，實際為 \(error)。")
                    return
                }
                #expect(code == "unexpected-result-partial")
            } catch {
                Issue.record("預期為 APIError，實際為 \(error)。")
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
