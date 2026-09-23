//
//  OllamaChatRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/22.
//

import Foundation

/// `POST https://ollama.com/api/chat` 的請求 body
struct OllamaChatRequest: Encodable {

    // MARK: - Properties

    /// 模型名稱
    let model: String

    /// 對話訊息陣列
    let messages: [Message]

    /// 是否啟用串流回應
    let stream: Bool
}

// MARK: - Nested Types

extension OllamaChatRequest {

    /// 單則對話訊息
    struct Message: Encodable {

        /// 角色 (例如 `user`)
        let role: String

        /// 訊息內容
        let content: String
    }
}
