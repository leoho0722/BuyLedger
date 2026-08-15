//
//  HTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 通用 HTTP 客戶端依賴
struct HTTPClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 對應到 `URLSession.data(for:)` 的可注入封裝 (buffered 回應)
    /// - Parameter request: 欲送出的請求
    /// - Returns: 回應 data 與 HTTP 回應資訊
    /// - Throws: 網路請求或 HTTP 狀態驗證失敗時拋出 ``APIError``
    var data: @Sendable (_ request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse)
    
    /// 可注入的 URLSession bytes 封裝，支援串流回應
    /// - Parameter request: 欲送出的請求
    /// - Returns: 逐位元組串流與 HTTP 回應資訊
    /// - Throws: 網路請求或 HTTP 狀態驗證失敗時拋出 ``APIError``
    var stream: @Sendable (_ request: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse)
}

// MARK: - Internal Method

extension HTTPClient {
    
    /// 以給定組件組裝 `URLRequest`、執行並驗證 2xx 狀態碼後回傳原始回應 data
    /// - Parameters:
    ///   - url: 目標 URL
    ///   - method: HTTP method (預設 `.get`)
    ///   - headers: 額外的 header 欄位 (預設無)
    ///   - body: 請求 body (預設無)
    ///   - timeout: 逾時秒數 (預設 60)
    /// - Returns: 2xx 回應的原始 data
    /// - Throws: 網路請求或 HTTP 狀態驗證失敗時拋出 ``APIError``
    func send(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) async throws(APIError) -> Data {
        let request = URLRequestBuilder(url: url, timeout: timeout)
            .method(method)
            .headers(headers)
            .body(body)
            .build()
        
        let result = try await data(request)
        let (responseData, response) = result
        
        guard 200...299 ~= response.statusCode else {
            throw APIError.http(statusCode: response.statusCode)
        }
        
        return responseData
    }
}

// MARK: - Dependency Values

extension HTTPClient: DependencyKey {
    
    private nonisolated static let session = URLSession(configuration: .default)
    
    /// App 執行時以 `URLSessionConfiguration.default` 的專屬 session 發送請求
    nonisolated static let liveValue: HTTPClient = HTTPClient(
        data: { (request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
            try await loadHTTPData(request, using: session)
        },
        stream: { (request: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) in
            try await loadHTTPStream(request, using: session)
        }
    )
    
    /// 測試與 Preview 不連線，固定回傳錯誤
    nonisolated static let testValue: HTTPClient = HTTPClient(
        data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
            throw APIError.transport(
                message: "HTTPClient.testValue 被呼叫；請在測試中以 withDependencies 注入。"
            )
        },
        stream: {
            (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) in
            throw APIError.transport(
                message: "HTTPClient.testValue 被呼叫；請在測試中以 withDependencies 注入。"
            )
        }
    )
    
    nonisolated static let previewValue: HTTPClient = testValue
}

// MARK: - Private Method

private extension HTTPClient {
    
    /// 使用 URLSession 取得完整 HTTP 回應
    /// - Parameters:
    ///   - request: 要送出的請求
    ///   - session: 用來執行請求的 URLSession
    /// - Returns: 回應資料與 HTTP 回應資訊
    /// - Throws: 網路請求失敗或回應不是 HTTP 時拋出 ``APIError``
    static func loadHTTPData(
        _ request: URLRequest,
        using session: URLSession
    ) async throws(APIError) -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(message: "回應不是 HTTPURLResponse。")
            }
            return (data, httpResponse)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(message: error.localizedDescription)
        }
    }
    
    /// 使用 URLSession 取得串流 HTTP 回應
    /// - Parameters:
    ///   - request: 要送出的請求
    ///   - session: 用來執行請求的 URLSession
    /// - Returns: 串流資料與 HTTP 回應資訊
    /// - Throws: 網路請求失敗或回應不是 HTTP 時拋出 ``APIError``
    static func loadHTTPStream(
        _ request: URLRequest,
        using session: URLSession
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(message: "回應不是 HTTPURLResponse。")
            }
            return (bytes, httpResponse)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(message: error.localizedDescription)
        }
    }
}

// MARK: - DependencyValues Accessor

extension DependencyValues {
    
    /// 通用 HTTP 客戶端
    var httpClient: HTTPClient {
        get { self[HTTPClient.self] }
        set { self[HTTPClient.self] = newValue }
    }
}
