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

/// 驗證 AI 商品摘要流程
@MainActor
struct AISummaryFeatureTests {

    // MARK: - Tests

    /// 驗證串流片段依序累積到摘要內容，完成後 `phase` 轉為 `.finished`
    @Test
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

    /// 驗證缺少 API 金鑰時轉為失敗並顯示設定未完成訊息
    @Test
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
        await store.receive(\.streamFailed, "AI 總結尚未完成設定，目前無法使用。") {
            $0.phase = .failed
            $0.errorMessage = "AI 總結尚未完成設定，目前無法使用。"
        }
    }

    /// 驗證 API 金鑰錯誤時顯示驗證失敗訊息
    @Test
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
        await store.receive(\.streamFailed, "AI 服務驗證失敗，目前無法使用總結功能。") {
            $0.phase = .failed
            $0.errorMessage = "AI 服務驗證失敗，目前無法使用總結功能。"
        }
    }

    /// 驗證傳輸失敗時保留部分內容並顯示友善連線錯誤訊息
    @Test
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
        await store.receive(\.streamFailed, "連線發生問題，請檢查網路後再試。") {
            $0.phase = .failed
            $0.errorMessage = "連線發生問題，請檢查網路後再試。"
        }
    }

    /// 驗證關閉摘要面板會取消串流並執行 `dismiss`，`phase` 維持 `.streaming`、不轉為失敗
    @Test
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

    /// 驗證串流逾時時保留部分內容並顯示截斷訊息
    @Test
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
            $0.truncationMessage = "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。"
        }
    }
}
