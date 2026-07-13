//
//  AISummaryFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import Foundation

/// AI 商品明細總結 sheet 的狀態與串流流程
///
/// 以 ``OllamaClient`` 串流 Markdown 總結；缺金鑰或服務錯誤時進入 `failed` 並提供重試，關閉時取消串流
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
        var errorMessage: String?

        // MARK: - Nested Types

        /// 串流階段
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
    }

    // MARK: - Action

    /// 總結 sheet 事件
    @CasePathable
    enum Action: Equatable {

        /// 畫面出現時開始串流
        case task

        /// 收到一段串流增量內容
        case chunkReceived(String)

        /// 串流正常結束
        case streamFinished

        /// 串流失敗，帶友善訊息
        case streamFailed(String)

        /// 使用者點擊重試
        case retryTapped

        /// 使用者點擊完成 (關閉 sheet)
        case closeTapped
    }

    // MARK: - Dependency Properties

    /// Ollama Cloud 串流 client
    @Dependency(OllamaClient.self) private var ollamaClient

    /// App 環境設定提供者
    @Dependency(\.appConfiguration) private var appConfiguration

    /// 關閉 sheet 用的 dismiss effect
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Cancel ID

    /// 串流 effect 的取消識別
    private enum CancelID {

        /// 串流任務
        case stream
    }

    // MARK: - Reducer Body

    /// 總結 reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task, .retryTapped:
                guard let apiKey = appConfiguration.ollamaAPIKey() else {
                    state.phase = .failed
                    state.errorMessage = "尚未設定 OLLAMA_API_KEY。"
                    return .none
                }
                state.phase = .streaming
                state.summaryText = ""
                state.errorMessage = nil

                let prompt = state.prompt
                let model = state.model
                let client = ollamaClient
                return .run { send in
                    do {
                        for try await chunk in client.streamSummary(prompt, model, apiKey) {
                            await send(.chunkReceived(chunk))
                        }
                        await send(.streamFinished)
                    } catch is CancellationError {
                        // sheet 關閉導致取消，靜默結束、不視為錯誤
                    } catch let error as APIError {
                        await send(.streamFailed(error.summaryFailureMessage))
                    } catch {
                        await send(.streamFailed("總結失敗，請稍後再試。"))
                    }
                }
                .cancellable(id: CancelID.stream, cancelInFlight: true)

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

            case .closeTapped:
                let dismiss = dismiss
                return .merge(
                    .cancel(id: CancelID.stream),
                    .run { _ in await dismiss() }
                )
            }
        }
    }
}

// MARK: - APIError Friendly Message

extension APIError {

    /// 對應到 AI 總結 sheet 的友善失敗訊息
    var summaryFailureMessage: String {
        switch self {
        case .invalidKey:
            "API key 無效或未設定，請確認 OLLAMA_API_KEY。"
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
