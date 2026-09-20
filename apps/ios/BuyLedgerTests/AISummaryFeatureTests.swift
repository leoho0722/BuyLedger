//
//  AISummaryFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/27.
//

import Clocks
import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
/// 驗證 AI 商品摘要流程
struct AISummaryFeatureTests {

    // MARK: - Helpers

    /// 建立測試用 AppConfiguration
    /// - Parameter key: Ollama API key；`nil` 表示未設定
    /// - Returns: 注入指定 key 的 AppConfiguration
    private func keyedConfiguration(_ key: String?) -> AppConfiguration {
        AppConfiguration(exchangeRateAPIKey: { nil }, ollamaAPIKey: { key })
    }

    // MARK: - Tests

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func streamingAccumulatesChunksThenFinishes() async {
        // Given

        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0.continuousClock = clock
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("# 標題\n")
                    continuation.yield("- 項目 A\n")
                    continuation.yield("- 項目 B")
                    continuation.finish()
                }
            })
        }

        // When

        await store.send(.task) {
            $0.phase = .streaming
        }
        // Then

        await store.receive(\.chunkReceived, "# 標題\n") {
            $0.summaryText = "# 標題\n"
        }
        await store.receive(\.chunkReceived, "- 項目 A\n") {
            $0.summaryText = "# 標題\n- 項目 A\n"
        }
        await store.receive(\.chunkReceived, "- 項目 B") {
            $0.summaryText = "# 標題\n- 項目 A\n- 項目 B"
        }
        await store.receive(\.streamFinished) {
            $0.phase = .finished
        }
    }

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func missingKeyFailsImmediately() async {
        // Given

        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration(nil)
        }

        // When

        await store.send(.task) {
            // Then

            $0.phase = .failed
            $0.errorMessage = "AI 總結尚未完成設定，目前無法使用。"
        }
    }

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func apiErrorEntersFailedState() async {
        // Given

        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0.continuousClock = clock
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.finish(throwing: APIError.invalidKey)
                }
            })
        }

        // When

        await store.send(.task) {
            $0.phase = .streaming
        }
        // Then

        await store.receive(\.streamFailed, "AI 服務驗證失敗，目前無法使用總結功能。") {
            $0.phase = .failed
            $0.errorMessage = "AI 服務驗證失敗，目前無法使用總結功能。"
        }
    }

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func transportErrorMapsToFriendlyMessage() async {
        // Given

        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0.continuousClock = clock
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("部分內容")
                    continuation.finish(
                        throwing: APIError.transport(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    )
                }
            })
        }

        // When

        await store.send(.task) {
            $0.phase = .streaming
        }
        // Then

        await store.receive(\.chunkReceived, "部分內容") {
            $0.summaryText = "部分內容"
        }
        await store.receive(\.streamFailed, "連線發生問題，請檢查網路後再試。") {
            $0.phase = .failed
            $0.errorMessage = "連線發生問題，請檢查網路後再試。"
        }
    }

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func closingSheetCancelsStreamingWithoutFailure() async {
        // Given

        let clock = TestClock()
        let cancellation = CancellationRecorder()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0.continuousClock = clock
            $0.dismiss = DismissEffect {
                Task {
                    await cancellation.markDismissed()
                }
            }
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("部分內容")
                    continuation.onTermination = { _ in
                        Task {
                            await cancellation.markCancelled()
                        }
                    }
                }
            })
        }

        // When

        await store.send(.task) {
            $0.phase = .streaming
        }
        // Then

        await store.receive(\.chunkReceived, "部分內容") {
            $0.summaryText = "部分內容"
        }
        await store.send(.closeTapped)

        // 給取消與 dismiss effect 最多 20 次 cooperative scheduling 機會
        let maxCancellationPollingAttempts = 20
        for _ in 0..<maxCancellationPollingAttempts where !(await cancellation.wasCancelled()) {
            await Task.yield()
        }

        let wasCancelled = await cancellation.wasCancelled()
        let wasDismissed = await cancellation.wasDismissed()
        #expect(wasCancelled)
        #expect(wasDismissed)
    }

    /// 驗證 AI 摘要功能在此情境下的狀態與效果
    @Test func slowStreamStopsAtOverallDurationLimitAndKeepsPartialContent() async {
        // Given

        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.appConfiguration = keyedConfiguration("k")
            $0.continuousClock = clock
            $0[OllamaClient.self] = OllamaClient(streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    let task = Task {
                        continuation.yield("第一段\n")
                        do {
                            // When

                            try await clock.sleep(for: .milliseconds(150))
                            guard !Task.isCancelled else { return }
                            continuation.yield("慢速段\n")
                            try await clock.sleep(for: .seconds(3600))
                        } catch is CancellationError {
                            // 測試替身被取消時停止產出
                        } catch {
                            // 測試替身不模擬其他錯誤
                        }
                    }
                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            })
        }

        await store.send(.task) {
            $0.phase = .streaming
        }
        // Then

        await store.receive(
            \.chunkReceived,
             "第一段\n"
        ) {
            $0.summaryText = "第一段\n"
        }
        await clock.advance(by: .milliseconds(150))
        await store.receive(
            \.chunkReceived,
             "慢速段\n"
        ) {
            $0.summaryText = "第一段\n慢速段\n"
        }
        await clock.advance(by: OllamaClient.overallStreamDuration)
        await store.receive(
            \.streamTimedOut,
             timeout: .seconds(2)
        ) {
            $0.phase = .finished
            $0.truncationMessage = "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。"
        }

        #expect(store.state.summaryText == "第一段\n慢速段\n")
        #expect(store.state.errorMessage == nil)
    }
}

// MARK: - Test Doubles
/// 記錄取消訊號
private actor CancellationRecorder {

    /// 是否已收到取消訊號
    private var cancelled = false

    /// 是否已收到關閉訊號
    private var dismissed = false

    /// 記錄已收到取消訊號
    func markCancelled() {
        cancelled = true
    }

    /// 記錄已收到關閉訊號
    func markDismissed() {
        dismissed = true
    }

    /// 回傳是否已收到取消訊號
    /// - Returns: 是否已標記為取消
    func wasCancelled() -> Bool {
        cancelled
    }

    /// 回傳是否已收到 dismiss 訊號
    /// - Returns: 是否已標記為 dismiss
    func wasDismissed() -> Bool {
        dismissed
    }
}
