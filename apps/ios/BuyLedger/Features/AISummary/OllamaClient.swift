//
//  OllamaClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import Foundation

/// 串接 Ollama Cloud chat streaming 的高階 client
///
/// 對 BuyLedger 隱藏 endpoint 與 NDJSON 串流細節：`streamSummary` 回傳逐段增量文字的 `AsyncThrowingStream`，
/// 失敗時以 ``APIError`` 結束串流，由 Reducer 決定 UI 呈現。逐位元組串流走 ``HTTPClient/stream`` 取得
/// `(URLSession.AsyncBytes, HTTPURLResponse)`，本 client 只負責組請求、判讀狀態碼與解析 NDJSON 行；
/// 並以可注入的 `streamSummary` closure 作為測試縫
struct OllamaClient: Sendable {

    // MARK: - Dependency Properties

    /// 以指定 prompt、模型與金鑰呼叫 Ollama Cloud chat streaming，回傳逐段增量內容的串流
    ///
    /// - 每個元素是一段 `message.content` 增量文字
    /// - 串流在收到 `done == true` 或連線結束時正常結束
    /// - 失敗時以 ``APIError`` 結束 (401/403 → `invalidKey`、其他非 2xx → `http`、連線錯誤 → `transport`)
    var streamSummary: @Sendable (_ prompt: String, _ model: String, _ apiKey: String) -> AsyncThrowingStream<String, Error>
}

extension OllamaClient {

    // MARK: - Static Method

    /// 解析單行 NDJSON 串流回應
    ///
    /// 空白行與無法解碼的壞行回 `nil` (呼叫端略過)；正常行回 `message.content` (缺漏時以空字串代替) 與 `done` 旗標
    /// - Parameter line: 串流的一行文字
    /// - Returns: `(content, done)`；無效行回 `nil`
    nonisolated static func parse(line: String) -> (content: String, done: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return nil
        }
        guard let decoded = try? JSONDecoder().decode(StreamLine.self, from: data) else {
            return nil
        }
        return (decoded.message?.content ?? "", decoded.done)
    }
}

extension OllamaClient: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時透過 ``HTTPClient/stream`` 串流 NDJSON
    nonisolated static let liveValue: OllamaClient = OllamaClient(
        streamSummary: { prompt, model, apiKey in
            @Dependency(\.httpClient) var httpClient

            return AsyncThrowingStream { [httpClient] continuation in
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
                            guard let parsed = OllamaClient.parse(line: line) else { continue }
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
                        continuation.finish(throwing: APIError.transport(message: String(describing: error)))
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
            AsyncThrowingStream { continuation in
                continuation.finish(
                    throwing: APIError.transport(message: "OllamaClient.testValue 被呼叫；請於測試中注入。")
                )
            }
        }
    )

    /// SwiftUI Preview 串出幾段固定 Markdown，讓 sheet 預覽能呈現串流渲染
    nonisolated static let previewValue: OllamaClient = OllamaClient(
        streamSummary: { _, _, _ in
            AsyncThrowingStream { continuation in
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

// MARK: - Request DTO

/// `POST https://ollama.com/api/chat` 的請求 body
private struct ChatRequest: Encodable {

    // MARK: - Data Properties

    /// 模型名稱
    let model: String

    /// 對話訊息陣列
    let messages: [Message]

    /// 是否啟用串流回應
    let stream: Bool

    // MARK: - Nested Types

    /// 單則對話訊息
    struct Message: Encodable {

        /// 角色 (例如 `user`)
        let role: String

        /// 訊息內容
        let content: String
    }
}

// MARK: - Response DTO

extension OllamaClient {

    // MARK: - Nested Types

    /// NDJSON 串流的單行回應 schema
    ///
    /// `message` 在最後一行 (`done == true`) 可能缺漏，故標為 optional；其餘統計欄位本 App 不使用，略過不解
    fileprivate struct StreamLine: Decodable {

        /// 該段的部分助理訊息
        let message: Message?

        /// 是否為串流的最後一段
        let done: Bool

        /// 串流訊息片段
        struct Message: Decodable {

            /// 增量文字內容
            let content: String
        }
    }
}
