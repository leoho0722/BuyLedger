//
//  HTTPClientProtocol.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// HTTP 傳輸操作與共用請求處理介面
protocol HTTPClientProtocol: Sendable {

    /// 取得完整傳輸回應
    ///
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 回應 `Data` 與 `HTTPURLResponse`
    /// - Throws: 傳輸失敗或回應無法轉為 `HTTPURLResponse` 時丟出 `.transport(underlying:)`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse)

    /// 取得串流傳輸回應
    ///
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 逐位元組的 `URLSession.AsyncBytes` 與 `HTTPURLResponse`
    /// - Throws: 傳輸失敗或回應無法轉為 `HTTPURLResponse` 時丟出 `.transport(underlying:)`
    func bytes(
        for request: URLRequest
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse)
}

// MARK: - Internal Method

extension HTTPClientProtocol {

    /// 組裝請求、執行完整傳輸並驗證 2xx 狀態碼
    ///
    /// - Parameters:
    ///   - url: 目標 `URL`
    ///   - method: `HTTPMethod`，預設為 `.get`
    ///   - headers: 額外的 header 欄位，預設為空
    ///   - body: 請求內容，預設為空
    ///   - timeout: 逾時秒數，預設為 60
    /// - Returns: 2xx 回應的原始 `Data`
    /// - Throws: 傳輸失敗或回應無法轉為 `HTTPURLResponse` 時丟出 `.transport(underlying:)`；
    ///   狀態碼不在 200 至 299 時丟出 `.http(statusCode:)`
    func send(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) async throws(APIError) -> Data {
        let request = makeRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            timeout: timeout
        )

        let (responseData, response) = try await data(for: request)
        try validateSuccessfulResponse(statusCode: response.statusCode)

        return responseData
    }

    /// 組裝請求、執行串流傳輸並驗證 2xx 狀態碼
    ///
    /// - Parameters:
    ///   - url: 目標 `URL`
    ///   - method: `HTTPMethod`，預設為 `.get`
    ///   - headers: 額外的 header 欄位，預設為空
    ///   - body: 請求內容，預設為空
    ///   - timeout: 逾時秒數，預設為 60
    /// - Returns: 2xx 回應的 `URLSession.AsyncBytes`
    /// - Throws: 傳輸失敗或回應無法轉為 `HTTPURLResponse` 時丟出 `.transport(underlying:)`；
    ///   狀態碼不在 200 至 299 時丟出 `.http(statusCode:)`
    func stream(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) async throws(APIError) -> URLSession.AsyncBytes {
        let request = makeRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            timeout: timeout
        )

        let (responseBytes, response) = try await bytes(for: request)
        try validateSuccessfulResponse(statusCode: response.statusCode)

        return responseBytes
    }

    /// 將回應資料解碼為指定的 `Decodable` 型別
    ///
    /// - Parameters:
    ///   - type: 目標解碼型別
    ///   - data: 要解碼的回應資料
    /// - Returns: 解碼後的值
    /// - Throws: JSON 解碼失敗時丟出 `.decoding(underlying:)`
    func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws(APIError) -> Value {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decoding(underlying: error as NSError)
        }
    }
}

// MARK: - Private Method

private extension HTTPClientProtocol {

    /// 依共用參數建立 `URLRequest`
    ///
    /// - Parameters:
    ///   - url: 目標 `URL`
    ///   - method: HTTP 請求方法
    ///   - headers: 額外的 header 欄位
    ///   - body: 請求本文
    ///   - timeout: 逾時秒數
    /// - Returns: 已套用所有參數的請求
    func makeRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        timeout: TimeInterval
    ) -> URLRequest {
        URLRequestBuilder(url: url, timeout: timeout)
            .method(method)
            .headers(headers)
            .body(body)
            .build()
    }

    /// 確認回應位於成功狀態碼範圍
    ///
    /// - Parameter statusCode: HTTP 回應狀態碼
    /// - Throws: 狀態碼不在 200 至 299 時丟出 `.http(statusCode:)`
    func validateSuccessfulResponse(statusCode: Int) throws(APIError) {
        guard 200...299 ~= statusCode else {
            throw .http(statusCode: statusCode)
        }
    }
}
