//
//  APIError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

/// BuyLedger 在發送網路請求時可能遇到的錯誤分類
enum APIError: Error, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 網路層錯誤 (DNS 失敗、timeout 等)
    case transport(message: String)
    
    /// 取回 HTTP 回應但 status code 不在預期範圍
    case http(statusCode: Int)
    
    /// 解碼失敗 (schema 不符或欄位缺漏)
    case decoding(message: String)
    
    /// API 業務錯誤 (HTTP 200 但 payload 帶 `result == "error"`)
    case apiError(code: String)
    
    /// API 配額耗盡
    case quotaExceeded
    
    /// 找不到 API key 或 key 無效
    case invalidKey
}
