//
//  AISummaryServiceTransportTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import Foundation
import Testing

@testable import BuyLedger

/// `AISummaryService` 的單元測試，以 `MockChatURLProtocol` 注入傳輸失敗並檢查錯誤包裝
struct AISummaryServiceTransportTests {

    /// 驗證 `streamSummary` 在收到回應前遇到傳輸失敗時，錯誤包成 `.transport`，底層 `NSError` 的網域與代碼與注入的失敗相同
    ///
    /// - Throws: 預期的 Service 錯誤未出現時由 `#require` 丟出測試失敗
    @Test
    func streamSummary_回應前傳輸失敗_包成傳輸錯誤並保留底層網域與代碼() async throws {
        // Given
        let apiKey = "summary-transport-error"
        MockChatURLProtocol.setStub(
            apiKey: apiKey,
            failure: .init(domain: NSURLErrorDomain, code: -1009)
        )
        let service = AISummaryServiceTestSupport.makeService()
        var actualError: (any Error)?

        // When
        do {
            for try await _ in service.streamSummary(
                "prompt",
                .anthropic,
                "model",
                apiKey
            ) {}
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
        #expect(actualUnderlying.domain == NSURLErrorDomain)
        #expect(actualUnderlying.code == -1009)
    }
}
