//
//  HTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

// MARK: - Protocol

/// HTTP 傳輸操作與共用請求處理介面
protocol HTTPClientProtocol: Sendable {

    /// 取得完整傳輸回應
    ///
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 回應內容與 HTTP 回應資訊 (狀態碼、標頭)
    /// - Throws: 傳輸失敗或回應無法轉為 `HTTPURLResponse` 時丟出 `.transport(underlying:)`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse)

    /// 取得串流傳輸回應
    ///
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 逐位元組讀取的回應內容與 HTTP 回應資訊
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
    /// - Returns: 2xx 回應的逐位元組串流
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
            throw .decoding(underlying: error as NSError)
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

// MARK: - Implementation

/// 使用注入的 `URLSession` 送出網路請求，並把傳輸失敗轉成 `APIError`
struct HTTPClient {

    // MARK: - Properties

    /// 實際送出網路請求的 `URLSession`，由 `init` 注入
    private let session: URLSession

    // MARK: - Init

    /// 建立使用指定 `URLSession` 的 `HTTPClient`
    ///
    /// - Parameter session: 執行網路請求的 `URLSession`
    init(session: URLSession) {
        self.session = session
    }
}

// MARK: - HTTPClientProtocol

extension HTTPClient: HTTPClientProtocol {

    /// 以注入的 `URLSession` 取得回應並轉換傳輸錯誤
    ///
    /// - Parameter request: 直接交給 `URLSession` 執行的請求
    /// - Returns: `URLSession` 回傳的原始內容與 HTTP 回應資訊
    /// - Throws: `URLSession` 傳輸失敗時以 `NSError` 包裝為 `.transport(underlying:)`；
    ///   非 `HTTPURLResponse` 回應以診斷碼 1 的 `NSError` 包裝為 `.transport(underlying:)`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) {
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch {
            throw .transport(underlying: error as NSError)
        }

        let (data, response) = result
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Self.responseTypeMismatchError()
        }
        return (data, httpResponse)
    }

    /// 以注入的 `URLSession` 取得串流並轉換傳輸錯誤
    ///
    /// - Parameter request: 直接交給 `URLSession` 執行的請求
    /// - Returns: `URLSession` 回傳的逐位元組串流與 HTTP 回應資訊
    /// - Throws: `URLSession` 傳輸失敗時以 `NSError` 包裝為 `.transport(underlying:)`；
    ///   非 `HTTPURLResponse` 回應以診斷碼 1 的 `NSError` 包裝為 `.transport(underlying:)`
    func bytes(
        for request: URLRequest
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let result: (URLSession.AsyncBytes, URLResponse)
        do {
            result = try await session.bytes(for: request)
        } catch {
            throw .transport(underlying: error as NSError)
        }

        let (bytes, response) = result
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Self.responseTypeMismatchError()
        }
        return (bytes, httpResponse)
    }
}

// MARK: - Private Method

private extension HTTPClient {

    /// 建立回應不是 `HTTPURLResponse` 時要丟出的錯誤
    ///
    /// - Returns: 底層為診斷碼 1 的 `NSError` 的 `.transport(underlying:)`
    static func responseTypeMismatchError() -> APIError {
        .transport(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.networking",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "回應不是 HTTPURLResponse。"]
            )
        )
    }
}

// MARK: - DependencyKey

/// 把 `HTTPClientProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 stub；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum HTTPClientKey: DependencyKey {

    /// App 執行時使用預設 `URLSession` 傳輸
    static var liveValue: any HTTPClientProtocol {
        HTTPClient(session: URLSession(configuration: .default))
    }

    #if DEBUG

    /// Preview 使用不連線的 HTTP client
    static var previewValue: any HTTPClientProtocol {
        PreviewHTTPClient()
    }

    #endif
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 Service 的 `liveValue` 以 `@Dependency(\.httpClient)` 取得的 HTTP 傳輸介面
    var httpClient: any HTTPClientProtocol {
        get { self[HTTPClientKey.self] }
        set { self[HTTPClientKey.self] = newValue }
    }
}

#if DEBUG

// MARK: - Preview

/// Preview 使用且所有請求都丟出 `.transport` 錯誤的 HTTP client
struct PreviewHTTPClient {

    // MARK: - Init

    /// 建立只供 Preview 與測試環境使用的 client
    init() {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PreviewHTTPClient 只能在 Preview、UI Test 或單元測試中使用"
        )
    }
}

// MARK: - HTTPClientProtocol

extension PreviewHTTPClient: HTTPClientProtocol {

    /// 不呼叫網路並丟出固定的診斷錯誤
    ///
    /// - Parameter request: 未使用的 `URLRequest`
    /// - Returns: 此實作不會回傳回應
    /// - Throws: 一律丟出 `.transport(underlying:)`
    func data(for request: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) {
        throw Self.previewTransportError()
    }

    /// 不呼叫網路串流並丟出固定的診斷錯誤
    ///
    /// - Parameter request: 未使用的 `URLRequest`
    /// - Returns: 此實作不會回傳串流
    /// - Throws: 一律丟出 `.transport(underlying:)`
    func bytes(
        for request: URLRequest
    ) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) {
        throw Self.previewTransportError()
    }
}

// MARK: - Private Method

private extension PreviewHTTPClient {

    /// 建立 Preview 使用的診斷錯誤
    ///
    /// - Returns: 底層為診斷碼 2 的 `NSError` 的 `.transport(underlying:)`
    static func previewTransportError() -> APIError {
        .transport(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.networking",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Preview HTTP client 不會發出網路請求。"]
            )
        )
    }
}

#endif
