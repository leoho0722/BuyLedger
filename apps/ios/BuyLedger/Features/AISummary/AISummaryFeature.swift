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
        case streamFailed(LocalizedStringResource)
        
        /// 串流達到整體時長上限，保留已收到內容
        case streamTimedOut
        
        /// 使用者點擊重試
        case retryTapped
        
        /// 使用者點擊完成 (關閉 sheet)
        case closeTapped
    }
    
    // MARK: - Nested Types
    
    /// 串流與逾時處理的結果
    private enum StreamResult: Sendable {
        
        // MARK: - Cases
        
        /// 串流正常完成
        case finished
        
        /// 串流達到整體時長上限
        case timedOut
        
        /// 串流被取消
        case cancelled
        
        /// 串流回傳可分類的 API 錯誤
        case apiFailure(APIError)
        
        /// 串流回傳無法分類的錯誤
        case unknownFailure
    }
    
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
                @Dependency(OllamaClient.self) var ollamaClient
                @Dependency(\.appConfiguration) var appConfiguration
                @Dependency(\.continuousClock) var clock

                guard let apiKey = appConfiguration.ollamaAPIKey() else {
                    state.phase = .failed
                    // 記錄狀態與下一步，不把環境變數名稱顯示給使用者。
                    state.errorMessage = "AI 總結尚未完成設定，目前無法使用。"
                    AppLogger.aiSummary.error(
                        "AI 總結無法啟動：OLLAMA_API_KEY 未注入 (xcconfig 未設定)"
                    )
                    return .none
                }
                state.phase = .streaming
                state.summaryText = ""
                state.errorMessage = nil
                state.truncationMessage = nil
                
                let prompt = state.prompt
                let model = state.model
                let client = ollamaClient
                let streamClock = clock
                return .run { send in
                    let result = await withTaskGroup(of: StreamResult.self) { group in
                        group.addTask {
                            do {
                                for try await chunk in client.streamSummary(prompt, model, apiKey) {
                                    await send(.chunkReceived(chunk))
                                }
                                return .finished
                            } catch let error as APIError {
                                return .apiFailure(error)
                            } catch {
                                return .unknownFailure
                            }
                        }
                        
                        group.addTask {
                            do {
                                try await streamClock.sleep(for: OllamaClient.overallStreamDuration)
                                return .timedOut
                            } catch is CancellationError {
                                return .cancelled
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
                        await send(.streamFailed(error.summaryFailureMessage))
                    case .unknownFailure:
                        await send(.streamFailed("總結失敗，請稍後再試。"))
                    case .cancelled:
                        // sheet 關閉導致取消，靜默結束、不視為錯誤
                        break
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
                
            case .streamTimedOut:
                state.phase = .finished
                state.truncationMessage = "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。"
                return .none
                
            case .closeTapped:
                @Dependency(\.dismiss) var dismiss
                let dismissAction = dismiss
                return .merge(
                    .cancel(id: CancelID.stream),
                    .run { _ in await dismissAction() }
                )
            }
        }
    }
}

// MARK: - APIError Friendly Message

extension APIError {
    
    /// 對應到 AI 總結 sheet 的友善失敗訊息
    var summaryFailureMessage: LocalizedStringResource {
        switch self {
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
