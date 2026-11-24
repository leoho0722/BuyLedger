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
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
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

    /// 驗證 `.view(.task)` 以 State 的供應商讀取金鑰，並把提示、供應商與模型原樣交給串流
    @Test
    @MainActor
    func task_State帶供應商與模型_以該供應商讀取金鑰並送出請求() async {
        // Given
        let clock = TestClock()
        let apiKeyProvider = LockIsolated<AISummaryProvider?>(nil)
        let streamPrompt = LockIsolated<String?>(nil)
        let streamProvider = LockIsolated<AISummaryProvider?>(nil)
        let streamModel = LockIsolated<String?>(nil)
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { provider in
                apiKeyProvider.setValue(provider)
                return "k"
            }
            $0.aiSummaryService.streamSummary = { prompt, provider, model, _ in
                streamPrompt.setValue(prompt)
                streamProvider.setValue(provider)
                streamModel.setValue(model)
                return AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("內容")
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
        await store.receive(\.chunkReceived, "內容") {
            $0.summaryText = "內容"
        }
        await store.receive(\.streamFinished) {
            $0.phase = .finished
        }
        #expect(apiKeyProvider.value == .anthropic)
        #expect(streamPrompt.value == "p")
        #expect(streamProvider.value == .anthropic)
        #expect(streamModel.value == "m")
    }

    /// 驗證缺少 API 金鑰時，`.view(.task)` 讓 `phase` 經 `.streaming` 轉為 `.failed`，`errorMessage` 為設定未完成的提示
    @Test
    @MainActor
    func task_缺少API金鑰_顯示設定未完成訊息() async {
        // Given
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
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
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
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
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
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
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
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
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
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
        await clock.advance(by: .seconds(30))
        await store.receive(\.streamTimedOut, timeout: .seconds(2)) {
            $0.phase = .finished
            $0.truncationMessage = "ai.summary.message.aiSummaryReached"
        }
    }

    /// 驗證串流沒有送出任何片段就正常結束時，`phase` 轉為 `.failed` 並顯示重試用的失敗訊息，不當成完成
    @Test
    @MainActor
    func task_串流沒有任何片段就結束_顯示失敗訊息() async {
        // Given
        let clock = TestClock()
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
                AsyncThrowingStream<String, any Error> {
                    $0.finish()
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.streamFinished) {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.summaryFailedTry"
        }
    }

    /// 驗證串流在總時限內沒有送出任何片段而逾時，`phase` 轉為 `.failed` 並顯示重試用的失敗訊息，
    /// `truncationMessage` 維持 `nil`，不當成截斷
    @Test
    @MainActor
    func task_串流逾時且沒有任何片段_顯示失敗而非截斷() async {
        // Given
        let clock = TestClock()
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
                AsyncThrowingStream<String, any Error> { _ in
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await clock.advance(by: .seconds(30))
        await store.receive(\.streamTimedOut, timeout: .seconds(2)) {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.summaryFailedTry"
        }
    }

    /// 驗證串流只送出空白內容就結束時，`summaryText` 保留收到的空白，`phase` 轉為 `.failed` 並顯示重試用的失敗訊息
    @Test
    @MainActor
    func task_串流只有空白內容就結束_顯示失敗訊息並保留空白內容() async {
        // Given
        let clock = TestClock()
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    continuation.yield("\n  ")
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
        await store.receive(\.chunkReceived, "\n  ") {
            $0.summaryText = "\n  "
        }
        await store.receive(\.streamFinished) {
            $0.phase = .failed
            $0.errorMessage = "ai.summary.message.summaryFailedTry"
        }
    }

    /// 驗證串流以各種 `APIError` 結束時，`phase` 轉為 `.failed`，並顯示對應的友善訊息 (key 與中英文字)
    ///
    /// - Parameter scenario: 串流結束時的錯誤與預期的訊息
    /// - Throws: 失敗訊息不存在時由 `#require` 丟出測試失敗
    @Test(arguments: FailureMessageScenario.allCases)
    @MainActor
    func task_串流以各種錯誤結束_顯示對應的失敗訊息(scenario: FailureMessageScenario) async throws {
        // Given
        let clock = TestClock()
        let store = TestStore(
            initialState: AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0.aiSummaryService.apiKey = { _ in
                "k"
            }
            $0.aiSummaryService.streamSummary = { _, _, _, _ in
                AsyncThrowingStream<String, any Error> {
                    $0.finish(throwing: scenario.error)
                }
            }
            $0.continuousClock = clock
        }

        // When
        await store.send(.view(.task)) {
            $0.phase = .streaming
        }

        // Then
        await store.receive(\.streamFailed) {
            $0.phase = .failed
            $0.errorMessage = scenario.expectedMessage
        }
        let message = try #require(store.state.errorMessage)
        #expect(message.key == scenario.expectedKey)
        #expect(AppLanguage.traditionalChinese.resolve(message) == scenario.expectedChineseText)
        #expect(AppLanguage.english.resolve(message) == scenario.expectedEnglishText)
    }

    /// 驗證 `State` 的 `errorMessage` 為 `nil` 時，`failureMessage` 退回通用的重試提示
    @Test
    func failureMessage_無錯誤原因_退回通用提示() {
        // Given
        let state = AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")

        // When
        let message = state.failureMessage

        // Then
        #expect(message == "orders.edit.message.pleaseTryAgain")
    }

    /// 驗證 `State` 的 `errorMessage` 有值時，`failureMessage` 沿用該訊息，不退回通用提示
    @Test
    func failureMessage_有錯誤原因_沿用該原因() {
        // Given
        var state = AISummaryFeature.State(prompt: "p", provider: .anthropic, model: "m")
        state.errorMessage = "ai.summary.message.summaryFailedTry"

        // When
        let message = state.failureMessage

        // Then
        #expect(message == "ai.summary.message.summaryFailedTry")
    }
}

// MARK: - Nested Types

extension AISummaryFeatureTests {

    /// 串流以 `APIError` 結束時，預期顯示的友善訊息
    enum FailureMessageScenario: CaseIterable, Sendable {

        /// API 配額耗盡
        case quotaExceeded

        /// 被限流 (狀態碼 429)
        case rateLimited

        /// 服務暫時無法使用 (狀態碼 529)
        case serviceUnavailable

        /// 回應內容無法解讀
        case invalidResponse

        /// 請求內容有問題 (錯誤代碼 `invalid_request`)
        case invalidRequest

        /// 模型拒答 (錯誤代碼 `refused`)
        case refused

        /// 串流結束時丟出的錯誤
        var error: APIError {
            switch self {
            case .quotaExceeded:
                .quotaExceeded

            case .rateLimited:
                .http(statusCode: 429)

            case .serviceUnavailable:
                .http(statusCode: 529)

            case .invalidResponse:
                .decoding(underlying: TestDependencies.makeUnderlyingError(message: "bad payload"))

            case .invalidRequest:
                .apiError(code: "invalid_request")

            case .refused:
                .apiError(code: "refused")
            }
        }

        /// 預期寫入狀態的失敗訊息
        var expectedMessage: LocalizedStringResource {
            switch self {
            case .quotaExceeded:
                "ai.summary.message.apiQuotaHas"

            case .rateLimited:
                LocalizedStringResource(
                    "ai.summary.message.serverErrorStatusCode",
                    defaultValue: "\(429)"
                )

            case .serviceUnavailable:
                LocalizedStringResource(
                    "ai.summary.message.serverErrorStatusCode",
                    defaultValue: "\(529)"
                )

            case .invalidResponse:
                "ai.summary.message.responseParsedTry"

            case .invalidRequest:
                LocalizedStringResource(
                    "ai.summary.message.serviceErrorCode",
                    defaultValue: "\("invalid_request")"
                )

            case .refused:
                LocalizedStringResource(
                    "ai.summary.message.serviceErrorCode",
                    defaultValue: "\("refused")"
                )
            }
        }

        /// 預期訊息在 String Catalog 的 key
        var expectedKey: String {
            switch self {
            case .quotaExceeded:
                "ai.summary.message.apiQuotaHas"

            case .rateLimited, .serviceUnavailable:
                "ai.summary.message.serverErrorStatusCode"

            case .invalidResponse:
                "ai.summary.message.responseParsedTry"

            case .invalidRequest, .refused:
                "ai.summary.message.serviceErrorCode"
            }
        }

        /// 預期的正體中文訊息
        var expectedChineseText: String {
            switch self {
            case .quotaExceeded:
                "API 配額已用罄，請稍後再試。"

            case .rateLimited:
                "伺服器回應錯誤 (429)，目前無法完成總結。"

            case .serviceUnavailable:
                "伺服器回應錯誤 (529)，目前無法完成總結。"

            case .invalidResponse:
                "回應格式無法解析，請稍後再試。"

            case .invalidRequest:
                "服務發生錯誤 (invalid_request)，請稍後再試。"

            case .refused:
                "服務發生錯誤 (refused)，請稍後再試。"
            }
        }

        /// 預期的英文訊息
        var expectedEnglishText: String {
            switch self {
            case .quotaExceeded:
                "The API quota has been exhausted. Try again later."

            case .rateLimited:
                "The server returned an error (429), so the summary could not be completed."

            case .serviceUnavailable:
                "The server returned an error (529), so the summary could not be completed."

            case .invalidResponse:
                "The response could not be parsed. Try again later."

            case .invalidRequest:
                "The service returned an error (invalid_request). Try again later."

            case .refused:
                "The service returned an error (refused). Try again later."
            }
        }
    }
}
