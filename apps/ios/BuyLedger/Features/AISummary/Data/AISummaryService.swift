//
//  AISummaryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation
import LKAIKit
import OSLog

/// AI 摘要串流與 API 金鑰讀取入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct AISummaryService: Sendable {

    // MARK: - Properties

    /// 呼叫指定供應商串流回傳摘要文字；每次收到一段文字就回傳一次
    ///
    /// - Parameters:
    ///   - prompt: 已組好的商品明細總結指令
    ///   - provider: 產生摘要的 AI 供應商
    ///   - model: 供應商的模型名稱
    ///   - apiKey: 供應商的 API 金鑰
    /// - Returns: 文字片段的串流，依序接起來就是完整摘要
    /// - Note: 迭代摘要串流時，金鑰無效或沒有權限會丟出 `.invalidKey`；傳輸失敗會丟出
    ///   `.transport(underlying:)`；其他錯誤依 LKAIKit 的錯誤種類轉成 `APIError`；
    ///   呼叫被取消時正常結束，不丟出錯誤
    /// - Note: Service 內建立的 `Task` 只為把 LKAIKit 串流接到回傳的 `AsyncThrowingStream`，
    ///   生命週期只由 `onTermination` 取消，不另外保存
    var streamSummary: StreamSummary

    /// 讀取指定供應商的 API 金鑰
    ///
    /// - Parameter provider: 要讀取金鑰的 AI 供應商
    /// - Returns: 設定的 API 金鑰，未設定時回傳 `nil`
    var apiKey: APIKey
}

// MARK: - Nested Types

extension AISummaryService {

    /// `streamSummary` 的函式型別
    typealias StreamSummary = @Sendable (
        _ prompt: String,
        _ provider: AISummaryProvider,
        _ model: String,
        _ apiKey: String
    ) -> AsyncThrowingStream<String, any Error>

    /// `apiKey` 的函式型別
    typealias APIKey = @Sendable (_ provider: AISummaryProvider) -> String?
}

// MARK: - DependencyKey

extension AISummaryService: DependencyKey {

    /// 正式 App 經注入的 `URLSession` 呼叫 LKAIKit 串流摘要，並從設定來源讀取金鑰；
    /// 必須是 computed property，測試以 `withDependencies` 換掉 `urlSession` 與設定來源
    static var liveValue: Self {
        @Dependency(\.urlSession) var urlSession
        @Dependency(\.appConfigurationStore) var configurationStore

        return Self(
            streamSummary: { prompt, provider, model, apiKey in
                // 新增供應商時在這裡加對應的 case；Haiku 5.5 沒有伺服器端的拒答備援，
                // 拒答備援維持預設的 `.disabled`
                let client: any LKAIChatClientProtocol
                switch provider {
                case .anthropic:
                    client = LKAnthropicClient(apiKey: apiKey, urlSession: urlSession)
                }

                // maxOutputTokens 是 Anthropic 必填；Haiku 5.5 的 thinking 計入此上限，
                // 實際長度由 30 秒整體上限決定
                let request = LKAIChatRequest(
                    model: model,
                    messages: [LKAIMessage(role: .user, text: prompt)],
                    maxOutputTokens: 16_000
                )

                return AsyncThrowingStream<String, any Error> { continuation in
                    let task = Task {
                        await Self.relay(client.stream(request), to: continuation)
                    }

                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            },
            apiKey: {
                configurationStore.string(forKey: $0.apiKeyConfigurationKey)
            }
        )
    }

    #if DEBUG

    /// Preview 使用固定的 Markdown 摘要與 API 金鑰
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "AISummaryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            streamSummary: { _, _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    let chunks = [
                        "## 商品明細總結\n\n",
                        "本批訂單共涵蓋多個品項，以下為重點觀察：\n\n",
                        "- **熱門品項**：藍牙耳機 x3、保溫瓶 x2\n",
                        "- **類別分佈**：以 3C 配件為主\n",
                        "- **金額區間**：單價集中在 NT$300–1,200\n",
                    ]
                    for chunk in chunks {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                }
            },
            apiKey: { _ in "preview-stub-key" }
        )
    }

    #endif

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        let emptyStream = AsyncThrowingStream<String, any Error> {
            $0.finish()
        }

        return Self(
            streamSummary: unimplemented(
                "AISummaryService.streamSummary",
                placeholder: emptyStream
            ),
            apiKey: unimplemented("AISummaryService.apiKey", placeholder: nil)
        )
    }
}

// MARK: - Private Method

private extension AISummaryService {

    /// 把 LKAIKit 的串流事件轉成摘要文字片段，依序交給 `continuation` 並在結束或失敗時收尾
    ///
    /// - Parameters:
    ///   - stream: LKAIKit 回傳的對話事件串流
    ///   - continuation: 摘要文字串流的 continuation
    /// - Note: 收到結束事件即結束；結束原因不是完成時只記錄原因到診斷紀錄，不記錄內容
    /// - Note: 失敗先依錯誤種類記錄不含網址的摘要，再依 `apiError(from:)` 轉成 `APIError`；
    ///   呼叫被取消 (如 sheet 關閉) 視為正常結束
    static func relay(
        _ stream: LKAIChatStream,
        to continuation: AsyncThrowingStream<String, any Error>.Continuation
    ) async {
        // 一般 `do` 推不出 `LKAIError`，`catch` 會拿到 `any Error`，所以明確標註 typed throws
        do throws(LKAIError) {
            for try await event in stream {
                switch event {
                case .textDelta(let text):
                    if !text.isEmpty {
                        continuation.yield(text)
                    }

                case .finished(let completion):
                    if completion.finishReason != .completed {
                        let reason = String(describing: completion.finishReason)
                        AppLogger.inference.warning("AI 摘要未完整結束：\(reason, privacy: .public)")
                    }
                    continuation.finish()
                    return

                @unknown default:
                    break
                }
            }
            continuation.finish()
        } catch {
            Self.logFailure(of: error)
            if let mappedError = Self.apiError(from: error) {
                continuation.finish(throwing: mappedError)
            } else {
                continuation.finish()
            }
        }
    }

    /// 依錯誤種類記錄串流失敗的摘要，只記種類名稱與不含網址的細節
    ///
    /// - Parameter error: LKAIKit 丟出的錯誤
    /// - Note: 為什麼是 `static`：呼叫點在 `liveValue` 建立的 closure 內，沒有實例可用
    /// - Note: `.transport` 只記 `URLError` 的代碼，`URLError` 的描述含完整請求網址
    /// - Note: `.invalidResponse` 的原因可能包住含網址的錯誤，只記種類名稱
    /// - Note: `.invalidRequest` 與 `.refused` 的細節可能引用使用者內容，標為 private
    /// - Note: 呼叫被取消不是失敗，不記錄
    static func logFailure(of error: LKAIError) {
        let logger = AppLogger.inference
        switch error {
        case .cancelled:
            break

        case .invalidAPIKey:
            logger.error("AI 摘要串流失敗：invalidAPIKey")

        case .permissionDenied:
            logger.error("AI 摘要串流失敗：permissionDenied")

        case .rateLimited:
            logger.error("AI 摘要串流失敗：rateLimited")

        case .quotaExceeded:
            logger.error("AI 摘要串流失敗：quotaExceeded")

        case .serviceUnavailable:
            logger.error("AI 摘要串流失敗：serviceUnavailable")

        case .invalidRequest(let message):
            logger.error("AI 摘要串流失敗：invalidRequest，細節 \(message ?? "無", privacy: .private)")

        case .refused(let detail):
            logger.error("AI 摘要串流失敗：refused，細節 \(detail ?? "無", privacy: .private)")

        case .transport(let underlying):
            logger.error(
                "AI 摘要串流失敗：transport，URLError 代碼 \(underlying.code.rawValue, privacy: .public)"
            )

        case .invalidResponse:
            logger.error("AI 摘要串流失敗：invalidResponse")

        @unknown default:
            logger.error("AI 摘要串流失敗：unknown")
        }
    }

    /// 把 LKAIKit 的錯誤轉成 App 的 `APIError`
    ///
    /// - Parameter error: LKAIKit 丟出的錯誤
    /// - Returns: 對應的 `APIError`；呼叫被取消時為 `nil`，由呼叫端視為正常結束
    static func apiError(from error: LKAIError) -> APIError? {
        switch error {
        case .invalidAPIKey, .permissionDenied:
            .invalidKey

        case .quotaExceeded:
            .quotaExceeded

        case .rateLimited:
            .http(statusCode: 429)

        case .serviceUnavailable(let statusCode, _):
            .http(statusCode: statusCode)

        case .invalidRequest:
            .apiError(code: "invalid_request")

        case .refused:
            .apiError(code: "refused")

        case .transport(let urlError):
            .transport(underlying: urlError as NSError)

        case .invalidResponse:
            .decoding(underlying: error as NSError)

        case .cancelled:
            nil

        @unknown default:
            .apiError(code: "unknown")
        }
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.aiSummaryService)` 取得的 AI Summary Service
    var aiSummaryService: AISummaryService {
        get { self[AISummaryService.self] }
        set { self[AISummaryService.self] = newValue }
    }
}
