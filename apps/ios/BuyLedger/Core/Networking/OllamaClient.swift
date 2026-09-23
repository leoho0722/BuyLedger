//
//  OllamaClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import Foundation

/// 串接 Ollama Cloud chat streaming 的高階 client
struct OllamaClient: Sendable {

    // MARK: - Properties

    /// AI 摘要串流的最長時間
    static let overallStreamDuration: Duration = .seconds(30)

    /// Ollama Cloud chat API 的固定網址；字面值常數初始化必定成功
    private static let chatURL = URL(string: "https://ollama.com/api/chat")!

    /// networking 層自有的診斷錯誤 domain
    private static let networkingErrorDomain = "com.leoho.BuyLedger.networking"

    /// 依賴未注入的診斷錯誤代碼
    private static let dependencyNotInjectedCode = 2

    /// 呼叫 Ollama Cloud 串流回傳摘要文字；每次收到一段文字就回傳一次
    ///
    /// - Parameters:
    ///   - prompt: 要送給模型的完整 prompt (已組好的商品明細總結指令)
    ///   - model: 使用的 Ollama 模型名稱
    ///   - apiKey: Ollama Cloud 的 API 金鑰
    /// - Returns: 逐段回傳摘要文字的串流
    var streamSummary: @Sendable (
        _ prompt: String,
        _ model: String,
        _ apiKey: String
    ) -> AsyncThrowingStream<String, any Error>
}

// MARK: - Internal Method

extension OllamaClient {

    /// 解析單行 NDJSON 串流回應
    ///
    /// - Parameter line: 串流的一行文字
    /// - Returns: `(content, done)`；無效行回 `nil`
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

extension OllamaClient: DependencyKey {

    /// App 執行時透過 ``HTTPClient/stream`` 串流 NDJSON
    static let liveValue: OllamaClient = OllamaClient(
        streamSummary: { prompt, model, apiKey in
            @Dependency(\.httpClient) var httpClient

            return AsyncThrowingStream<String, any Error> { [httpClient] continuation in
                let task = Task {
                    do {
                        let bodyData = try JSONEncoder().encode(
                            OllamaChatRequest(
                                model: model,
                                messages: [
                                    OllamaChatRequest.Message(role: "user", content: prompt)
                                ],
                                stream: true
                            )
                        )
                        let request = URLRequestBuilder(url: Self.chatURL)
                            .method(.post)
                            .header("Authorization", "Bearer \(apiKey)")
                            .header("Content-Type", "application/json")
                            .body(bodyData)
                            .build()

                        let (bytes, response) = try await httpClient.stream(request)

                        guard 200...299 ~= response.statusCode else {
                            if response.statusCode == 401 || response.statusCode == 403 {
                                throw APIError.invalidKey
                            }
                            throw APIError.http(statusCode: response.statusCode)
                        }

                        for try await line in bytes.lines {
                            try Task.checkCancellation()
                            guard let parsed = OllamaClient.parse(line: line) else {
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
                    } catch {
                        if error is CancellationError {
                            // sheet 關閉導致取消，視為正常結束
                            continuation.finish()
                        } else if let apiError = error as? APIError {
                            continuation.finish(throwing: apiError)
                        } else {
                            continuation.finish(
                                throwing: APIError.transport(underlying: error as NSError)
                            )
                        }
                    }
                }

                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }
    )

    /// 測試預設拋出 transport 錯誤；具體測試以 `withDependencies` 注入 stub stream
    static let testValue: OllamaClient = OllamaClient(
        streamSummary: { _, _, _ in
            AsyncThrowingStream<String, any Error> { continuation in
                continuation.finish(throwing: Self.dependencyNotInjectedError())
            }
        }
    )

    /// Preview 使用固定 Markdown 串流
    static let previewValue: OllamaClient = OllamaClient(
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
        }
    )
}

// MARK: - Private Method

private extension OllamaClient {

    /// 建立依賴未注入的 transport 錯誤
    ///
    /// - Returns: 帶自有 domain 與診斷代碼的 transport 錯誤
    static func dependencyNotInjectedError() -> APIError {
        .transport(
            underlying: NSError(
                domain: networkingErrorDomain,
                code: dependencyNotInjectedCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "OllamaClient.testValue 被呼叫；請於測試中注入。",
                ]
            )
        )
    }
}
