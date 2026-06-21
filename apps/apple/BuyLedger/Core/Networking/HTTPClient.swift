//
//  HTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 通用 HTTP 客戶端依賴。
///
/// 抽象化 `URLSession` 的細節，讓上層 client 只關心「發 request、拿 buffered (Data) 或逐位元組串流的回應」。
/// 測試時可注入 closure 直接回傳預先準備好的 fixture，無需架設 mock server。
struct HTTPClient: Sendable {

    // MARK: - Dependency Properties

    /// 對應到 `URLSession.data(for:)` 的可注入封裝 (buffered 回應)。
    var data: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    /// 對應到 `URLSession.bytes(for:)` 的可注入封裝，回傳逐位元組串流供 NDJSON / SSE 等串流式回應使用。
    var stream: @Sendable (URLRequest) async throws -> (URLSession.AsyncBytes, HTTPURLResponse)
}

// MARK: - Request

extension HTTPClient {

    /// 以給定組件組裝 `URLRequest`、執行並驗證 2xx 狀態碼後回傳原始回應 data。
    ///
    /// 收斂各高階 client 重複的「組 request → 打 ``data`` → 檢查狀態碼」流程；解碼與領域錯誤判讀仍由呼叫端依各 API 形狀處理。
    /// - Parameters:
    ///   - url: 目標 URL。
    ///   - method: HTTP method (預設 `.get`)。
    ///   - headers: 額外的 header 欄位 (預設無)。
    ///   - body: 請求 body (預設無)。
    ///   - timeout: 逾時秒數 (預設 60)。
    /// - Returns: 2xx 回應的原始 data。
    func send(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) async throws -> Data {
        let request = URLRequestBuilder(url: url, timeout: timeout)
            .method(method)
            .headers(headers)
            .body(body)
            .build()

        let (responseData, response) = try await data(request)

        guard 200...299 ~= response.statusCode else {
            throw APIError.http(statusCode: response.statusCode)
        }

        return responseData
    }
}

extension HTTPClient: DependencyKey {

    // MARK: - Dependency Values

    /// `liveValue` 共用的設定化 session：以 `URLSessionConfiguration.default` 建立，取代 `URLSession.shared` 以保留 configuration 控制權。
    private nonisolated static let session = URLSession(configuration: .default)

    /// App 執行時以 `URLSessionConfiguration.default` 的專屬 session 發送請求。
    nonisolated static let liveValue: HTTPClient = HTTPClient(
        data: { request in
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(message: "回應不是 HTTPURLResponse。")
            }

            return (data, httpResponse)
        },
        stream: { request in
            let (bytes, response) = try await session.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.transport(message: "回應不是 HTTPURLResponse。")
            }

            return (bytes, httpResponse)
        }
    )

    /// 測試與 Preview 使用：永遠拋出 `transport` 錯誤，避免意外打到真實網路。
    nonisolated static let testValue: HTTPClient = HTTPClient(
        data: { _ in
            throw APIError.transport(message: "HTTPClient.testValue 被呼叫；請在測試中以 withDependencies 注入。")
        },
        stream: { _ in
            throw APIError.transport(message: "HTTPClient.testValue 被呼叫；請在測試中以 withDependencies 注入。")
        }
    )

    nonisolated static let previewValue: HTTPClient = testValue
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// 通用 HTTP 客戶端。
    var httpClient: HTTPClient {
        get { self[HTTPClient.self] }
        set { self[HTTPClient.self] = newValue }
    }
}
