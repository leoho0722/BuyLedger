//
//  AISummaryServiceTests+Transport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension AISummaryServiceTests {

    /// 驗證串流傳輸失敗會包成 `.transport` 錯誤，底層 `NSError` 的網域與代碼與注入的失敗一致
    ///
    /// - Throws: 預期的 Service 錯誤未出現時由 `#require` 丟出測試失敗
    @Test
    func streamSummary_串流中傳輸失敗_包成傳輸錯誤並保留底層網域與代碼() async throws {
        // Given
        let apiKey = "summary-transport-error"
        MockURLProtocol.setStub(
            authorization: "Bearer \(apiKey)",
            statusCode: 200,
            body: Data(),
            failure: .init(
                afterByteCount: 0,
                domain: "com.leoho.BuyLedgerTests.stream-failure",
                code: 42
            )
        )
        let service = withDependencies {
            $0.httpClient = makeHTTPClient()
        } operation: {
            AISummaryService.liveValue
        }
        var actualError: (any Error)?

        // When
        do {
            for try await _ in service.streamSummary("prompt", "model", apiKey) {}
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? APIError)
        let underlyingError: (any Error & Sendable)?
        switch error {
        case .transport(let underlying):
            underlyingError = underlying

        case .http, .decoding, .apiError, .quotaExceeded, .invalidKey:
            underlyingError = nil
        }
        let underlying = try #require(underlyingError)
        let actualUnderlying = underlying as NSError
        #expect(actualUnderlying.domain == "com.leoho.BuyLedgerTests.stream-failure")
        #expect(actualUnderlying.code == 42)
    }
}
