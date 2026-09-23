//
//  AISummaryFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import Foundation
import OSLog

/// AI 商品明細總結 sheet 的狀態與串流流程
@Reducer
struct AISummaryFeature {

    // MARK: - State

    /// 總結 sheet 狀態
    @ObservableState
    struct State: Equatable {

        /// 已組好的完整 prompt
        let prompt: String

        /// 使用的 Ollama 模型名稱
        let model: String

        /// 累加的串流總結文字 (Markdown)
        var summaryText: String = ""

        /// 目前的串流階段
        var phase: Phase = .idle

        /// 失敗時顯示的友善訊息
        var errorMessage: LocalizedStringResource?

        /// 串流逾時時顯示的截斷說明；逾時不是失敗，不使用 `errorMessage`
        var truncationMessage: LocalizedStringResource?
    }

    // MARK: - Action

    /// 總結 sheet 事件
    @CasePathable
    enum Action: Equatable {

        /// 使用者可直接操作的總結畫面事件
        ///
        /// - Parameter action: 使用者在總結畫面執行的操作
        case view(View)

        /// 收到一段串流增量內容
        ///
        /// - Parameter text: 新收到的總結文字
        case chunkReceived(String)

        /// 串流失敗，帶友善訊息
        ///
        /// - Parameter message: 顯示給使用者的失敗訊息
        case streamFailed(LocalizedStringResource)

        /// 串流正常結束
        case streamFinished

        /// 串流達到整體時長上限，保留已收到內容
        case streamTimedOut

        /// 總結畫面事件
        @CasePathable
        enum View {

            /// 畫面出現時開始串流
            case task

            /// 使用者點擊重試
            case retryTapped

            /// 使用者點擊完成並關閉 sheet
            case closeTapped
        }
    }

    // MARK: - Dependencies

    /// Ollama Cloud AI 摘要串流 client
    @Dependency(OllamaClient.self) private var ollamaClient

    /// App 執行環境的設定來源
    @Dependency(\.appConfiguration) private var appConfiguration

    /// 用於串流整體逾時競速的時鐘
    @Dependency(\.continuousClock) private var continuousClock

    /// 關閉總結 sheet 的呈現依賴
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Body

    /// 總結 reducer
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension AISummaryFeature {

    /// AI 摘要的串流階段
    enum Phase: Equatable {

        /// 尚未開始
        case idle

        /// 串流進行中
        case streaming

        /// 已完成
        case finished

        /// 失敗
        case failed
    }

    /// 串流與逾時處理的結果
    private enum StreamResult: Sendable {

        /// 串流正常完成
        case finished

        /// 串流達到整體時長上限
        case timedOut

        /// 串流被取消
        case cancelled

        /// 串流回傳可分類的 API 錯誤
        ///
        /// - Parameter error: API 層回傳的錯誤
        case apiFailure(APIError)

        /// 串流回傳無法分類的錯誤
        case unknownFailure
    }

    /// 串流 effect 的取消識別
    private enum CancelID {

        /// 串流任務
        case stream
    }
}

// MARK: - Private Method

private extension AISummaryFeature {

    /// 依收到的事件更新總結狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的總結狀態，直接就地修改
    ///   - action: 這次收到的總結事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task), .view(.retryTapped):
            return startStream(state: &state)

        case .view(.closeTapped):
            let dismissAction = dismiss
            return .merge(
                .cancel(id: CancelID.stream),
                .run { _ in await dismissAction() }
            )

        case let .chunkReceived(text):
            state.summaryText += text
            return .none

        case .streamFinished:
            state.phase = .finished
            return .none

        case let .streamFailed(message):
            state.phase = .failed
            state.errorMessage = message
            return .none

        case .streamTimedOut:
            state.phase = .finished
            state.truncationMessage = "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。"
            return .none
        }
    }

    /// 清除前一次內容並開始 AI 摘要串流
    ///
    /// - Parameter state: 目前的總結狀態，直接就地修改
    /// - Returns: 讀取金鑰並處理串流的 Effect
    func startStream(state: inout State) -> Effect<Action> {
        state.phase = .streaming
        state.summaryText = ""
        state.errorMessage = nil
        state.truncationMessage = nil

        let prompt = state.prompt
        let model = state.model
        let client = ollamaClient
        let configuration = appConfiguration
        let streamClock = continuousClock
        return .run { send in
            guard let apiKey = configuration.ollamaAPIKey() else {
                AppLogger.inference.error(
                    "AI 總結無法啟動：OLLAMA_API_KEY 未注入 (xcconfig 未設定)"
                )
                await send(.streamFailed("AI 總結尚未完成設定，目前無法使用。"))
                return
            }

            let result = await withTaskGroup(of: StreamResult.self) { group in
                group.addTask {
                    do {
                        for try await chunk in client.streamSummary(prompt, model, apiKey) {
                            await send(.chunkReceived(chunk))
                        }
                        return .finished
                    } catch {
                        if Task.isCancelled {
                            return .cancelled
                        }
                        if let apiError = error as? APIError {
                            return .apiFailure(apiError)
                        }
                        return .unknownFailure
                    }
                }

                group.addTask {
                    do {
                        try await streamClock.sleep(for: OllamaClient.overallStreamDuration)
                        return .timedOut
                    } catch {
                        return .cancelled
                    }
                }

                guard let result = await group.next() else {
                    return StreamResult.cancelled
                }
                group.cancelAll()
                return result
            }

            switch result {
            case .finished:
                await send(.streamFinished)

            case .timedOut:
                await send(.streamTimedOut)

            case let .apiFailure(error):
                await send(.streamFailed(Self.summaryFailureMessage(for: error)))

            case .unknownFailure:
                await send(.streamFailed("總結失敗，請稍後再試。"))

            case .cancelled:
                break
            }
        }
        .cancellable(id: CancelID.stream, cancelInFlight: true)
    }

    /// 對應到 AI 總結 sheet 的友善失敗訊息
    ///
    /// - Parameter error: AI 服務回傳的 API 錯誤
    /// - Returns: 顯示給使用者的失敗訊息
    static func summaryFailureMessage(for error: APIError) -> LocalizedStringResource {
        switch error {
        case .invalidKey:
            "AI 服務驗證失敗，目前無法使用總結功能。"

        case .quotaExceeded:
            "API 配額已用罄，請稍後再試。"

        case let .http(statusCode):
            "伺服器回應錯誤 (\(statusCode))，目前無法完成總結。"

        case .transport:
            "連線發生問題，請檢查網路後再試。"

        case .decoding:
            "回應格式無法解析，請稍後再試。"

        case let .apiError(code):
            "服務發生錯誤 (\(code))，請稍後再試。"
        }
    }
}
