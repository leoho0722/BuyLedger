//
//  PreviewHTTPClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Foundation

/// Preview 使用且所有請求都丟出 transport 錯誤的 HTTP client
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
    /// - Returns: 帶相同診斷碼的 `.transport(underlying:)`
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
