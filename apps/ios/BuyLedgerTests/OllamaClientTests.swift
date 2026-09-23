//
//  OllamaClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/27.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證 `OllamaClient` 的串流回應處理
struct OllamaClientTests {

    // MARK: - Tests

    /// 驗證串流回應能取出文字內容與完成狀態
    @Test func parseExtractsContentFromStreamingLine() throws {
        // Given
        let line = #"""
        {"model":"gemma4:31b-cloud","message":{"role":"assistant","content":"Hello"},"done":false}
        """#

        // When
        let parsed = try #require(OllamaClient.parse(line: line))

        // Then
        #expect(parsed.content == "Hello")
        #expect(parsed.done == false)
    }

    /// 驗證串流最後一行會標記為完成
    @Test func parseMarksDoneOnFinalLine() throws {
        // Given
        let line = #"{"model":"m","message":{"role":"assistant","content":""},"done":true,"total_duration":123456}"#

        // When
        let parsed = try #require(OllamaClient.parse(line: line))

        // Then
        #expect(parsed.content.isEmpty)
        #expect(parsed.done)
    }

    /// 驗證缺少訊息時仍回傳空內容與完成狀態
    @Test func parseTreatsMissingMessageAsEmptyContent() throws {
        // Given
        let line = #"{"model":"m","done":true}"#

        // When
        let parsed = try #require(OllamaClient.parse(line: line))

        // Then
        #expect(parsed.content.isEmpty)
        #expect(parsed.done)
    }

    /// 驗證空白或格式錯誤的串流行會被忽略
    ///
    /// - Parameter line: 要解析的空白或格式錯誤文字
    @Test(arguments: ["   ", "", "this is not json", "{\"message\": "])
    func parseReturnsNilForInvalidLine(_ line: String) {
        // Given

        // When
        let parsed = OllamaClient.parse(line: line)

        // Then
        #expect(parsed == nil)
    }

    /// 驗證未注入的測試替身會拋出網路錯誤
    @Test func testValueThrowsWhenInvoked() async {
        // Given
        let client = OllamaClient.testValue

        // When
        var capturedError: (any Error)?
        do {
            for try await _ in client.streamSummary("prompt", "model", "key") {}
        } catch {
            capturedError = error
        }

        // Then
        guard let capturedError else {
            Issue.record("未注入的 client 應拋出錯誤")
            return
        }
        guard let apiError = capturedError as? APIError else {
            Issue.record("未注入的 client 應拋出 transport 錯誤")
            return
        }
        guard case let .transport(underlying) = apiError else {
            Issue.record("未注入的 client 應拋出 transport 錯誤")
            return
        }
        let nsError = underlying as NSError
        #expect(nsError.domain == "com.leoho.BuyLedger.networking")
        #expect(nsError.code == 2)
    }

    /// 驗證預覽替身會輸出固定的 Markdown 摘要
    @Test func previewValueStreamsCannedMarkdown() async throws(any Error) {
        // Given
        let client = OllamaClient.previewValue

        // When
        var accumulated = ""
        var chunkCount = 0
        for try await chunk in client.streamSummary("prompt", "model", "key") {
            accumulated += chunk
            chunkCount += 1
        }

        // Then
        #expect(chunkCount == 5)
        #expect(accumulated.hasPrefix("## 商品明細總結"))
    }
}
