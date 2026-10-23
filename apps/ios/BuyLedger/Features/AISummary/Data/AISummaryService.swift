//
//  AISummaryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

/// AI 摘要串流與 API 金鑰讀取入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct AISummaryService: Sendable {

    // MARK: - Properties

    /// AI 摘要串流的最長時間
    static let overallStreamDuration: Duration = .seconds(30)

    /// Ollama Cloud chat API 的固定網址；字面值常數初始化必定成功
    private static let chatURL = URL(string: "https://ollama.com/api/chat")!

    /// Ollama Cloud API key 在 `Info.plist` 中的設定名稱
    private static let apiKeyConfigurationKey = "OLLAMA_API_KEY"

    /// 呼叫 Ollama Cloud 串流回傳摘要文字；每次收到一段文字就回傳一次
    ///
    /// - Parameters:
    ///   - prompt: 已組好的商品明細總結指令
    ///   - model: Ollama 模型名稱
    ///   - apiKey: Ollama Cloud API 金鑰
    /// - Returns: 文字片段的串流，依序接起來就是完整摘要
    /// - Note: 迭代摘要串流時，金鑰無效會丟出 `.invalidKey`；傳輸失敗會丟出
    ///   `.transport(underlying:)`；其他狀態碼不在 200 至 299 的回應會丟出 `.http(statusCode:)`
    var streamSummary: StreamSummary

    /// 讀取 Ollama Cloud API 金鑰
    ///
    /// - Returns: 設定的 API 金鑰，未設定時回傳 `nil`
    var apiKey: APIKey
}

// MARK: - Nested Types

extension AISummaryService {

    /// `streamSummary` 的函式型別
    typealias StreamSummary = @Sendable (
        _ prompt: String,
        _ model: String,
        _ apiKey: String
    ) -> AsyncThrowingStream<String, any Error>

    /// `apiKey` 的函式型別
    typealias APIKey = @Sendable () -> String?
}

// MARK: - Internal Method

extension AISummaryService {

    /// 解析串流回應的其中一行；回應每行一筆 JSON
    ///
    /// - Parameter line: 串流的一行文字
    /// - Returns: 這一行帶來的文字片段，以及是否為串流的最後一段；空行或無法解析時為 `nil`
    static func parse(line: String) -> (content: String, done: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return nil
        }
        let decoded: OllamaChatResponse
        do {
            decoded = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
        } catch {
            return nil
        }
        return (decoded.message?.content ?? "", decoded.done)
    }
}

// MARK: - DependencyKey

extension AISummaryService: DependencyKey {

    /// 正式 App 使用注入的 `HTTPClient` 送出網路請求，並從設定來源讀取金鑰；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 `HTTPClient` 與設定來源
    static var liveValue: Self {
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.appConfigurationStore) var configurationStore

        return Self(
            streamSummary: { prompt, model, apiKey in
                AsyncThrowingStream<String, any Error> { [httpClient] continuation in
                    let task = Task {
                        do {
                            let bodyData = try JSONEncoder().encode(
                                OllamaChatRequest(
                                    model: model,
                                    messages: [
                                        OllamaChatRequest.Message(role: "user", content: prompt),
                                    ],
                                    stream: true
                                )
                            )

                            let bytes = try await httpClient.stream(
                                url: Self.chatURL,
                                method: .post,
                                headers: [
                                    "Authorization": "Bearer \(apiKey)",
                                    "Content-Type": "application/json",
                                ],
                                body: bodyData
                            )

                            for try await line in bytes.lines {
                                try Task.checkCancellation()
                                guard let parsed = Self.parse(line: line) else {
                                    continue
                                }
                                if !parsed.content.isEmpty {
                                    continuation.yield(parsed.content)
                                }
                                if parsed.done {
                                    continuation.finish()
                                    return
                                }
                            }
                            continuation.finish()
                        } catch is CancellationError {
                            // sheet 關閉導致取消，視為正常結束
                            continuation.finish()
                        } catch let apiError as APIError {
                            switch apiError {
                            case .http(statusCode: 401), .http(statusCode: 403):
                                continuation.finish(throwing: APIError.invalidKey)

                            case .transport, .http, .decoding, .apiError, .quotaExceeded,
                                    .invalidKey:
                                continuation.finish(throwing: apiError)
                            }
                        } catch {
                            continuation.finish(
                                throwing: APIError.transport(underlying: error as NSError)
                            )
                        }
                    }

                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            },
            apiKey: {
                configurationStore.string(forKey: Self.apiKeyConfigurationKey)
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
            streamSummary: { _, _, _ in
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
            apiKey: { "preview-stub-key" }
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

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.aiSummaryService)` 取得的 AI Summary Service
    var aiSummaryService: AISummaryService {
        get { self[AISummaryService.self] }
        set { self[AISummaryService.self] = newValue }
    }
}
