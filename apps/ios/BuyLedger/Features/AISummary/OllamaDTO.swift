//
//  OllamaDTO.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import Foundation

// MARK: - Request DTO

/// `POST https://ollama.com/api/chat` 的請求 body
struct ChatRequest: Encodable {
    
    // MARK: - Data Properties
    
    /// 模型名稱
    let model: String
    
    /// 對話訊息陣列
    let messages: [Message]
    
    /// 是否啟用串流回應
    let stream: Bool
}

// MARK: - Nested Types

extension ChatRequest {
    
    /// 單則對話訊息
    struct Message: Encodable {
        
        /// 角色 (例如 `user`)
        let role: String
        
        /// 訊息內容
        let content: String
    }
}

// MARK: - Response DTO

/// NDJSON 串流的單行回應 schema
struct ChatResponse: Decodable {
    
    // MARK: - Data Properties
    
    /// 該段的部分助理訊息
    let message: Message?
    
    /// 是否為串流的最後一段
    let done: Bool
}

// MARK: - Nested Types

extension ChatResponse {
    
    /// 串流訊息片段
    struct Message: Decodable {
        
        /// 增量文字內容
        let content: String
    }
}
