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
    
    // MARK: - Static Properties
    
    /// AI 摘要串流的最長時間
    nonisolated static let overallStreamDuration: Duration = .seconds(30)
    
    // MARK: - Dependency Properties
    
    /// 呼叫 Ollama Cloud 串流回傳摘要文字
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
    /// - Parameter line: 串流的一行文字
    /// - Returns: `(content, done)`；無效行回 `nil`
    nonisolated static func parse(line: String) -> (content: String, done: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return nil
        }
        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            return nil
        }
        return (decoded.message?.content ?? "", decoded.done)
    }
}

// MARK: - Dependency Values

extension OllamaClient: DependencyKey {
    
    /// App 執行時透過 ``HTTPClient/stream`` 串流 NDJSON
    nonisolated static let liveValue: OllamaClient = OllamaClient(
        streamSummary: { prompt, model, apiKey in
            @Dependency(\.httpClient) var httpClient
            
            return AsyncThrowingStream<String, any Error> { [httpClient] continuation in
                let task = Task {
                    do {
                        guard let url = URL(string: "https://ollama.com/api/chat") else {
                            throw APIError.transport(message: "URL 組合失敗。")
                        }
                        
                        let bodyData = try JSONEncoder().encode(
                            ChatRequest(
                                model: model,
                                messages: [ChatRequest.Message(role: "user", content: prompt)],
                                stream: true
                            )
                        )
                        let request = URLRequestBuilder(url: url)
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
                    } catch is CancellationError {
                        // sheet 關閉導致取消，視為正常結束
                        continuation.finish()
                    } catch let error as APIError {
                        continuation.finish(throwing: error)
                    } catch {
                        let errorCode = (error as NSError).code
                        continuation.finish(
                            throwing: APIError.transport(message: "網路請求失敗 (錯誤代碼：\(errorCode))。")
                        )
                    }
                }
                
                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }
    )
    
    /// 測試預設拋出 transport 錯誤；具體測試以 `withDependencies` 注入 stub stream
    nonisolated static let testValue: OllamaClient = OllamaClient(
        streamSummary: { _, _, _ in
            AsyncThrowingStream<String, any Error> { continuation in
                continuation.finish(
                    throwing: APIError.transport(message: "OllamaClient.testValue 被呼叫；請於測試中注入。")
                )
            }
        }
    )
    
    /// Preview 使用固定 Markdown 串流
    nonisolated static let previewValue: OllamaClient = OllamaClient(
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
