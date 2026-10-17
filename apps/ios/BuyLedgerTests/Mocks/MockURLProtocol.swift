//
//  MockURLProtocol.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation

/// 依授權標頭回傳固定 HTTP 狀態、本文或傳輸錯誤的 `URLProtocol` 替身；
/// 由 URL Loading System 在其他執行緒呼叫，可變狀態只有以 `LockIsolated` 保護的 static 回應表，
/// 故標記 `@unchecked Sendable`
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// 依授權標頭保存尚未使用的回應
    private static let responsesState = LockIsolated<[String: StubResponse]>([:])
}

// MARK: - Nested Types

extension MockURLProtocol {

    /// 單次回應的狀態碼、本文與可選的傳輸失敗
    private struct StubResponse: Sendable {

        /// 決定測試請求收到的 HTTP 成功或失敗狀態
        let statusCode: Int

        /// 無傳輸錯誤時送出的本文；有錯誤時只送出前 `afterByteCount` 個位元組
        let body: Data

        /// 本文部分送出後要回報的傳輸錯誤
        let failure: StubFailure?
    }

    /// 部分本文送出後回報的傳輸錯誤
    struct StubFailure: Sendable {

        /// 傳輸失敗前送出的位元組數
        let afterByteCount: Int

        /// 傳給底層 `NSError` 的錯誤分類識別字
        let domain: String

        /// 傳給底層 `NSError` 的錯誤碼
        let code: Int
    }
}

// MARK: - Internal Method

extension MockURLProtocol {

    /// 設定指定授權標頭的回應
    ///
    /// - Parameters:
    ///   - authorization: 要比對的授權標頭
    ///   - statusCode: 固定回傳的 HTTP 狀態碼
    ///   - body: 固定回傳的回應本文
    ///   - failure: 部分本文送出後回報的錯誤，預設為 `nil`
    static func setStub(
        authorization: String,
        statusCode: Int,
        body: Data,
        failure: StubFailure? = nil
    ) {
        responsesState.withValue {
            $0[authorization] = StubResponse(statusCode: statusCode, body: body, failure: failure)
        }
    }
}

// MARK: - URLProtocol

extension MockURLProtocol {

    /// 接受測試建立的 `URLSession` 請求
    ///
    /// - Parameter request: `URLSession` 提供的請求
    /// - Returns: 固定回傳 `true`，讓測試請求交由此 protocol 處理
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// 原樣使用測試請求
    ///
    /// - Parameter request: `URLSession` 提供的請求
    /// - Returns: 未修改的請求
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// 回傳預先設定的狀態、本文與可選傳輸錯誤
    override func startLoading() {
        if let authorization = request.value(forHTTPHeaderField: "Authorization"),
           let stub = Self.responsesState.withValue({ $0.removeValue(forKey: authorization) }),
           let url = request.url,
           let response = HTTPURLResponse(
               url: url,
               statusCode: stub.statusCode,
               httpVersion: "HTTP/1.1",
               headerFields: ["Content-Type": "application/x-ndjson"]
           ) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let failure = stub.failure {
                let partialBody = Data(stub.body.prefix(failure.afterByteCount))
                client?.urlProtocol(self, didLoad: partialBody)
                client?.urlProtocol(
                    self,
                    didFailWithError: NSError(domain: failure.domain, code: failure.code)
                )
                return
            }
            client?.urlProtocol(self, didLoad: stub.body)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(
                    domain: "com.leoho.BuyLedgerTests.mock-url-protocol",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "找不到符合授權標頭的 URLProtocol 回應。"]
                )
            )
        }
    }

    /// 此測試替身不需要額外處理停止載入
    override func stopLoading() {
    }
}
