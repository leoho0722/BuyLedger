//
//  AISummaryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

import Foundation

/// AI 摘要串流與 API 金鑰讀取入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct AISummaryService: Sendable {

    // MARK: - Properties

    /// AI 摘要串流的最長時間
    static let overallStreamDuration: Duration = .seconds(30)

    /// Ollama Cloud chat API 的固定網址；字面值常數初始化必定成功
    static let chatURL = URL(string: "https://ollama.com/api/chat")!

    /// Ollama Cloud API key 在 `Info.plist` 中的設定名稱
    static let apiKeyConfigurationKey = "OLLAMA_API_KEY"

    /// 呼叫 Ollama Cloud 串流回傳摘要文字；每次收到一段文字就回傳一次
    ///
    /// - Parameters:
    ///   - prompt: 已組好的商品明細總結指令
    ///   - model: Ollama 模型名稱
    ///   - apiKey: Ollama Cloud API 金鑰
    /// - Returns: 逐段回傳摘要文字的串流
    /// - Note: 迭代摘要串流時，金鑰無效會丟出 `.invalidKey`；傳輸失敗會丟出
    ///   `.transport(underlying:)`；其他非 2xx 回應會丟出 `.http(statusCode:)`
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

    /// 解析單行 NDJSON 串流回應
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
