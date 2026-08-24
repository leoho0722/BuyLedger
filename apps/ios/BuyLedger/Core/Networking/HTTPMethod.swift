//
//  HTTPMethod.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

/// HTTP 請求方法
enum HTTPMethod: String, Sendable {
    
    // MARK: - Cases
    
    /// 取得資源
    case get = "GET"
    
    /// 新增資源
    case post = "POST"
    
    /// 取代資源
    case put = "PUT"
    
    /// 局部更新資源
    case patch = "PATCH"
    
    /// 刪除資源
    case delete = "DELETE"
}
