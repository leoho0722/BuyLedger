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

        /// 已組好、要送給 AI 的完整指令 (prompt)
        let prompt: String

        /// 產生摘要的 AI 供應商
        let provider: AISummaryProvider

        /// 使用的模型名稱，屬於 `provider`
        let model: String

        /// 累加的串流總結文字 (Markdown)
        var summaryText: String = ""

        /// 目前的串流階段
        var phase: Phase = .idle

        /// 失敗時顯示的友善訊息
        var errorMessage: LocalizedStringResource?

        /// 串流逾時且已有內容時顯示的截斷說明；有內容的逾時不是失敗，不使用 `errorMessage`
        var truncationMessage: LocalizedStringResource?

        /// 失敗畫面顯示的訊息，沒有具體原因時退回通用提示
        var failureMessage: LocalizedStringResource {
            errorMessage ?? "orders.edit.message.pleaseTryAgain"
        }

        /// 是否已收到可顯示的摘要內容 (去除空白與換行後不為空)
        var hasSummaryContent: Bool {
            !summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
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

        /// 串流失敗，畫面改顯示失敗狀態
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

            /// 使用者點擊關閉按鈕，取消進行中的串流並關閉 sheet
            case closeTapped
        }
    }

    // MARK: - Dependencies

    /// AI 摘要串流與 API 金鑰讀取
    @Dependency(\.aiSummaryService) private var aiSummaryService

    /// 用於串流整體逾時競速的時鐘
    @Dependency(\.continuousClock) private var continuousClock

    /// 關閉總結 sheet 的動作
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Body

    /// 只負責組合 reducer，總結自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension AISummaryFeature {

    /// 串流 effect 的取消識別
    private enum CancelID {

        /// 串流任務
        case stream
    }

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

        /// 串流因可辨識的原因失敗
        ///
        /// - Parameter error: 失敗原因 (金鑰無效、額度用完、連線失敗、伺服器回應錯誤或資料格式不符)
        case apiFailure(APIError)

        /// 串流回傳無法分類的錯誤
        case unknownFailure
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
            return .merge(.cancel(id: CancelID.stream), .run { _ in await dismissAction() })

        case .chunkReceived(let text):
            state.summaryText += text
            return .none

        case .streamFailed(let message):
            state.phase = .failed
            state.errorMessage = message
            return .none

        case .streamFinished:
            guard state.hasSummaryContent else {
                AppLogger.inference.warning("AI 摘要串流結束但沒有任何內容")
                state.phase = .failed
                state.errorMessage = "ai.summary.message.summaryFailedTry"
                return .none
            }
            state.phase = .finished
            return .none

        case .streamTimedOut:
            guard state.hasSummaryContent else {
                AppLogger.inference.warning("AI 摘要串流逾時且沒有任何內容")
                state.phase = .failed
                state.errorMessage = "ai.summary.message.summaryFailedTry"
                return .none
            }
            state.phase = .finished
            state.truncationMessage = "ai.summary.message.aiSummaryReached"
            return .none
        }
    }

    /// 對應到 AI 總結 sheet 的友善失敗訊息
    ///
    /// - Parameter error: AI 服務回傳的失敗原因
    /// - Returns: 顯示給使用者的失敗訊息
    static func summaryFailureMessage(for error: APIError) -> LocalizedStringResource {
        switch error {
        case .invalidKey:
            "ai.summary.message.aiServiceAuthentication"

        case .quotaExceeded:
            "ai.summary.message.apiQuotaHas"

        case .http(let statusCode):
            LocalizedStringResource(
                "ai.summary.message.serverErrorStatusCode",
                defaultValue: "\(statusCode)"
            )

        case .transport:
            "ai.summary.message.connectionProblemOccurred"

        case .decoding:
            "ai.summary.message.responseParsedTry"

        case .apiError(let code):
            LocalizedStringResource("ai.summary.message.serviceErrorCode", defaultValue: "\(code)")
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
        let provider = state.provider
        let model = state.model
        let service = aiSummaryService
        let streamClock = continuousClock
        // 串流整體時長上限；逾時時有內容就保留並標示截斷，沒有內容就顯示失敗
        let streamDuration: Duration = .seconds(30)
        return .run { send in
            if let apiKey = service.apiKey(provider) {
                let result = await withTaskGroup(of: StreamResult.self) { group in
                    group.addTask {
                        do {
                            let stream = service.streamSummary(
                                prompt,
                                provider,
                                model,
                                apiKey
                            )
                            for try await chunk in stream {
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
                            try await streamClock.sleep(for: streamDuration)
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

                case .apiFailure(let error):
                    await send(.streamFailed(Self.summaryFailureMessage(for: error)))

                case .unknownFailure:
                    await send(.streamFailed("ai.summary.message.summaryFailedTry"))

                case .cancelled:
                    break
                }
            } else {
                let keyName = provider.apiKeyConfigurationKey
                AppLogger.inference.error(
                    "AI 總結無法啟動：\(keyName, privacy: .public) 未注入 (xcconfig 未設定)"
                )
                await send(.streamFailed("ai.summary.message.aiSummariesSet"))
            }
        }
        .cancellable(id: CancelID.stream, cancelInFlight: true)
    }
}
