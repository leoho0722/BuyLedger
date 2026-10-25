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

/// `AISummaryFeature` 的單元測試，以 TestStore 逐步驗證串流、失敗與關閉流程
struct AISummaryFeatureTests {

    /// 驗證畫面送出 `.view(.task)` 後，串流的三段片段依序累積到 `summaryText`，串流結束時 `phase` 轉為 `.finished`
    @Test
    @MainActor
    func task_收到多段摘要_依序累積並標記完成() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("# 標題\n")
                    continuation.yield("- 項目 A\n")
                    continuation.yield("- 項目 B")
                    continuation.finish()
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
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

    /// 驗證缺少 API 金鑰時，`.view(.task)` 讓 `phase` 經 `.streaming` 轉為 `.failed`，`errorMessage` 為設定未完成的提示
    @Test
    @MainActor
    func task_缺少API金鑰_顯示設定未完成訊息() async {
        // Given
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                nil
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.streamFailed, "ai.summary.message.aiSummariesSet") {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.aiSummariesSet"
        }
    }

    /// 驗證金鑰有值但服務以 `APIError.invalidKey` 回報金鑰無效時，`phase` 轉為 `.failed`，並顯示 AI 服務驗證失敗的提示
    @Test
    @MainActor
    func task_服務回報金鑰無效_顯示驗證失敗訊息() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _ in
                AsyncThrowingStream<String, any Error> {
                    $0.finish(throwing: APIError.invalidKey)
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.streamFailed, "ai.summary.message.aiServiceAuthentication") {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.aiServiceAuthentication"
        }
    }

    /// 驗證串流送出部分內容後傳輸失敗 (`APIError.transport`) 時，`summaryText` 保留內容，`phase` 轉為 `.failed`，並顯示連線問題提示
    @Test
    @MainActor
    func task_收到部分內容後傳輸失敗_保留內容並顯示連線錯誤() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("部分內容")
                    continuation.finish(
                        throwing: APIError.transport(
                            underlying: TestDependencies.makeUnderlyingError(message: "boom")
                        )
                    )
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.chunkReceived, "部分內容") {
            $0.summaryText = "部分內容"
        }
        await store.receive(\.streamFailed, "ai.summary.message.connectionProblemOccurred") {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.connectionProblemOccurred"
        }
    }

    /// 驗證串流進行中按下關閉時，串流被取消、`dismiss` 執行一次，`phase` 維持 `.streaming` 而不轉為失敗
    @Test
    @MainActor
    func closeTapped_串流進行中_取消串流並關閉摘要() async {
        // Given
        let clock = TestClock()
        let isStreamTerminated = LockIsolated(false)
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("部分內容")
                    continuation.onTermination = { _ in
                        isStreamTerminated.setValue(true)
                    }
                }
            }
            $0.continuousClock = clock
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }
        await store.receive(\.chunkReceived, "部分內容") {
            $0.summaryText = "部分內容"
        }

        // When
        await store.send(.view(.closeTapped))

        // Then
        await store.finish()
        #expect(store.state.phase == .streaming)
        #expect(isStreamTerminated.value)
        #expect(dismissCallCount.value == 1)
    }

    /// 驗證串流超過總時限時，已收到的內容保留，`phase` 轉為 `.finished` 而非失敗，並設定 `truncationMessage` 為截斷提示
    @Test
    @MainActor
    func task_串流超過總時限_保留部分內容並標記截斷() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: AISummaryFeature.State(prompt: "p", model: "m")) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = {
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    let task = Task {
                        continuation.yield("第一段\n")
                        try? await clock.sleep(for: .milliseconds(150)) // 失敗可忽略，因為只在替身被取消時丟出
                        guard !Task.isCancelled else {
                            return
                        }
                        continuation.yield("慢速段\n")
                        try? await clock.sleep(for: .seconds(3600)) // 失敗可忽略，因為只在替身被取消時丟出
                    }
                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.chunkReceived, "第一段\n") {
            $0.summaryText = "第一段\n"
        }
        await clock.advance(by: .milliseconds(150))
        await store.receive(\.chunkReceived, "慢速段\n") {
            $0.summaryText = "第一段\n慢速段\n"
        }
        await clock.advance(by: AISummaryService.overallStreamDuration)
        await store.receive(\.streamTimedOut, timeout: .seconds(2)) {
            $0.phase = .finished
            $0.truncationMessage = "ai.summary.message.aiSummaryReached"
        }
    }

    /// 驗證 `State` 的 `errorMessage` 為 `nil` 時，`failureMessage` 退回通用的重試提示
    @Test
    func failureMessage_無錯誤原因_退回通用提示() {
        // Given
        let state = AISummaryFeature.State(prompt: "p", model: "m")

        // When
        let message = state.failureMessage

        // Then
        #expect(message == "orders.edit.message.pleaseTryAgain")
    }

    /// 驗證 `State` 的 `errorMessage` 有值時，`failureMessage` 沿用該訊息，不退回通用提示
    @Test
    func failureMessage_有錯誤原因_沿用該原因() {
        // Given
        var state = AISummaryFeature.State(prompt: "p", model: "m")
        state.errorMessage = "ai.summary.message.summaryFailedTry"

        // When
        let message = state.failureMessage

        // Then
        #expect(message == "ai.summary.message.summaryFailedTry")
    }
}
