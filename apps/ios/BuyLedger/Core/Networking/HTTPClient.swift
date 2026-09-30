//
//  HTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation

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
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 回應 `Data` 與 `HTTPURLResponse`
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
    /// - Parameter request: 要送出的 `URLRequest`
    /// - Returns: 逐位元組的 `URLSession.AsyncBytes` 與 `HTTPURLResponse`
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
