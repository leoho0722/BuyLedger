//
//  URLRequestBuilder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation

/// 以鏈式 API 組裝 `URLRequest`，集中各 client 重複的「設 method / header / body」樣板
///
/// 值型別：每個設定方法回傳套用後的新 builder，最後以 ``build()`` 取出組裝完成的 `URLRequest`
struct URLRequestBuilder: Sendable {

    // MARK: - Data Properties

    /// 累積設定中的請求
    private var request: URLRequest

    // MARK: - Init

    /// 以目標 URL 與逾時建立 builder
    /// - Parameters:
    ///   - url: 目標 URL
    ///   - timeout: 逾時秒數 (預設 60)
    init(url: URL, timeout: TimeInterval = 60) {
        request = URLRequest(url: url, timeoutInterval: timeout)
    }
}

// MARK: - Building

extension URLRequestBuilder {

    /// 設定 HTTP method
    /// - Parameter method: HTTP method
    /// - Returns: 套用後的 builder
    func method(_ method: HTTPMethod) -> Self {
        var copy = self
        copy.request.httpMethod = method.rawValue
        return copy
    }

    /// 設定單一 header 欄位
    /// - Parameters:
    ///   - field: header 欄位名
    ///   - value: 欄位值
    /// - Returns: 套用後的 builder
    func header(_ field: String, _ value: String) -> Self {
        var copy = self
        copy.request.setValue(value, forHTTPHeaderField: field)
        return copy
    }

    /// 批次設定多個 header 欄位
    /// - Parameter headers: header 欄位名 → 值的映射
    /// - Returns: 套用後的 builder
    func headers(_ headers: [String: String]) -> Self {
        var copy = self
        for (field, value) in headers {
            copy.request.setValue(value, forHTTPHeaderField: field)
        }
        return copy
    }

    /// 設定請求 body
    /// - Parameter body: 請求 body；`nil` 代表無 body
    /// - Returns: 套用後的 builder
    func body(_ body: Data?) -> Self {
        var copy = self
        copy.request.httpBody = body
        return copy
    }

    /// 取出組裝完成的 `URLRequest`
    /// - Returns: 組裝完成的請求
    func build() -> URLRequest {
        request
    }
}
