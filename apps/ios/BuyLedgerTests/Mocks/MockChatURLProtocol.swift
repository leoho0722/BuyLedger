//
//  MockChatURLProtocol.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/24.
//

import ComposableArchitecture
import Foundation

/// 依 `x-api-key` 標頭回傳固定 SSE 回應或傳輸錯誤，並記錄收到的請求的 `URLProtocol` 替身
///
/// - Note: URL Loading System 在其他執行緒呼叫，可變狀態只有 `LockIsolated` 保護的靜態表，故標記 `@unchecked Sendable`
/// - Note: 回應與請求紀錄都以金鑰為索引，每個測試使用自己的金鑰，並行的測試之間不會互相取走
/// - Note: URL Loading System 自己建立實例，測試只能經型別層級的狀態溝通，所以回應表、請求紀錄、
///   `setStub`、`lastRequest` 與 `canInit`、`canonicalRequest` 都是 static
final class MockChatURLProtocol: URLProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// 依金鑰索引、尚未被請求取用的回應
    private static let responsesState = LockIsolated<[String: StubResponse]>([:])

    /// 依金鑰索引、最後一次收到的請求
    private static let recordedRequestsState = LockIsolated<[String: RecordedRequest]>([:])
}

// MARK: - Nested Types

extension MockChatURLProtocol {

    /// 單次回應的狀態碼與本文，或回應前就失敗的傳輸錯誤
    private enum StubResponse: Sendable {

        /// 回傳狀態碼與 SSE 本文
        ///
        /// - Parameters:
        ///   - statusCode: 測試請求收到的 HTTP 狀態碼
        ///   - body: 送出的回應本文
        ///   - finishesLoading: 送完本文後是否結束載入；`false` 時連線維持開啟，等請求被取消
        case response(statusCode: Int, body: Data, finishesLoading: Bool)

        /// 回應前就以傳輸錯誤結束
        ///
        /// - Parameter failure: 要回報的傳輸錯誤
        case failure(StubFailure)
    }

    /// 回應前回報的傳輸錯誤
    struct StubFailure: Sendable {

        /// 傳給底層 `NSError` 的錯誤分類識別字
        let domain: String

        /// 傳給底層 `NSError` 的錯誤碼
        let code: Int
    }

    /// 替身收到的請求內容
    struct RecordedRequest: Sendable {

        /// HTTP 方法
        let method: String?

        /// 請求網址
        let url: URL?

        /// 請求標頭，名稱一律是小寫
        let headers: [String: String]

        /// 請求本文；沒有本文時為 `nil`
        let body: Data?
    }
}

// MARK: - Internal Method

extension MockChatURLProtocol {

    /// 設定指定金鑰的回應
    ///
    /// - Parameters:
    ///   - apiKey: 要比對的 `x-api-key` 標頭值
    ///   - statusCode: 固定回傳的 HTTP 狀態碼
    ///   - body: 固定回傳的回應本文
    static func setStub(apiKey: String, statusCode: Int, body: Data) {
        responsesState.withValue {
            $0[apiKey] = .response(statusCode: statusCode, body: body, finishesLoading: true)
        }
    }

    /// 設定指定金鑰的回應：送出狀態碼與部分本文後不結束載入，連線維持開啟直到請求被取消
    ///
    /// - Parameters:
    ///   - apiKey: 要比對的 `x-api-key` 標頭值
    ///   - statusCode: 固定回傳的 HTTP 狀態碼
    ///   - body: 固定回傳的部分回應本文
    static func setUnfinishedStub(apiKey: String, statusCode: Int, body: Data) {
        responsesState.withValue {
            $0[apiKey] = .response(statusCode: statusCode, body: body, finishesLoading: false)
        }
    }

    /// 設定指定金鑰的請求在回應前就失敗
    ///
    /// - Parameters:
    ///   - apiKey: 要比對的 `x-api-key` 標頭值
    ///   - failure: 回報的傳輸錯誤
    static func setStub(apiKey: String, failure: StubFailure) {
        responsesState.withValue {
            $0[apiKey] = .failure(failure)
        }
    }

    /// 取得指定金鑰最後一次收到的請求
    ///
    /// - Parameter apiKey: 請求的 `x-api-key` 標頭值
    /// - Returns: 最後一次收到的請求；沒有收到時為 `nil`
    static func lastRequest(apiKey: String) -> RecordedRequest? {
        recordedRequestsState.withValue { $0[apiKey] }
    }
}

// MARK: - URLProtocol

extension MockChatURLProtocol {

    /// 接受所有請求，交由此 protocol 處理
    ///
    /// - Parameter request: `URLSession` 提供的請求
    /// - Returns: 固定回傳 `true`
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

    /// 記錄請求，再取出並移除金鑰對應的預先設定回應；找不到回應時回報錯誤
    override func startLoading() {
        guard let apiKey = request.value(forHTTPHeaderField: "x-api-key") else {
            client?.urlProtocol(self, didFailWithError: makeMissingStubError())
            return
        }
        Self.recordedRequestsState.withValue {
            $0[apiKey] = RecordedRequest(
                method: request.httpMethod,
                url: request.url,
                headers: Dictionary(
                    (request.allHTTPHeaderFields ?? [:]).map { ($0.key.lowercased(), $0.value) },
                    uniquingKeysWith: { first, _ in first }
                ),
                body: readBody()
            )
        }
        guard let stub = Self.responsesState.withValue({ $0.removeValue(forKey: apiKey) }) else {
            client?.urlProtocol(self, didFailWithError: makeMissingStubError())
            return
        }
        switch stub {
        case .failure(let failure):
            client?.urlProtocol(
                self,
                didFailWithError: NSError(domain: failure.domain, code: failure.code)
            )

        case .response(let statusCode, let body, let finishesLoading):
            guard let url = request.url,
                  let response = HTTPURLResponse(
                      url: url,
                      statusCode: statusCode,
                      httpVersion: "HTTP/1.1",
                      headerFields: ["Content-Type": "text/event-stream"]
                  ) else {
                client?.urlProtocol(self, didFailWithError: makeMissingStubError())
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            if finishesLoading {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    /// 略過停止載入的處理，回應已於 `startLoading()` 中同步送出；
    /// 不結束載入的回應在請求被取消時由這裡收尾，不需另外處理
    override func stopLoading() {
    }
}

// MARK: - Private Method

private extension MockChatURLProtocol {

    /// 找不到符合金鑰的預設回應時回報的錯誤
    ///
    /// - Returns: 指出找不到預設回應的 `NSError`
    func makeMissingStubError() -> NSError {
        NSError(
            domain: "com.leoho.BuyLedgerTests.mock-chat-url-protocol",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "找不到符合金鑰的 URLProtocol 回應。"]
        )
    }

    /// 讀出請求本文；`URLProtocol` 收到的本文在 `httpBodyStream`
    ///
    /// - Returns: 請求本文；沒有本文時為 `nil`
    func readBody() -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        stream.open()
        defer {
            stream.close()
        }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}
