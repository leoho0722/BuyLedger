//
//  OllamaChatResponse.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/22.
//

import Foundation

/// Ollama Cloud NDJSON 串流的單行回應
struct OllamaChatResponse: Decodable {

    // MARK: - Properties

    /// 該段的部分助理訊息
    let message: Message?

    /// 是否為串流的最後一段
    let done: Bool
}

// MARK: - Nested Types

extension OllamaChatResponse {

    /// 串流訊息片段
    struct Message: Decodable {

        /// 增量文字內容
        let content: String
    }
}
