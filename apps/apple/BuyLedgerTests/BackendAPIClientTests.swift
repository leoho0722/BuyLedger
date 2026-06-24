//
//  BackendAPIClientTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/22.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// ``BackendAPIClient`` 的 PATCH / DELETE 形狀與 token 夾帶測試
///
/// 以注入的 ``HTTPClient`` 攔截 `URLRequest` (免架真實網路)：斷言 URL 路由、HTTP method、
/// `Authorization: Bearer`、`Content-Type` 與 body `{ id, changedFields, fieldClocks }` 形狀
@MainActor
struct BackendAPIClientTests {

    // MARK: - patchOrder

    @Test
    func patchOrderSendsCorrectBodyAndToken() async throws {
        let captured = CapturedRequest()
        let responseJSON = """
        { "appliedFieldClocks": { "customerName": "1700000000000:000000:server" }, "deletedAt": null }
        """

        let response = try await withDependencies {
            $0.appConfiguration = .testValue
            $0.appConfiguration.backendBaseURL = { URL(string: "http://localhost:4000/api") }
            $0.httpClient = Self.stubHTTPClient(captured: captured, json: responseJSON)
        } operation: {
            try await BackendAPIClient.liveValue.patchOrder(
                "TEST-TOKEN",
                "BL-123",
                ["customerName": .string("王小明")],
                ["customerName": "1700000000000:000000:device-a"]
            )
        }

        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:4000/api/orders/BL-123")
        #expect(request.httpMethod == "PATCH")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer TEST-TOKEN")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(Self.requestBody(request))
        let object = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        #expect(object["id"] as? String == "BL-123")
        let changedFields = try #require(object["changedFields"] as? [String: Any])
        #expect(changedFields["customerName"] as? String == "王小明")
        let fieldClocks = try #require(object["fieldClocks"] as? [String: Any])
        #expect(fieldClocks["customerName"] as? String == "1700000000000:000000:device-a")

        #expect(response.appliedFieldClocks["customerName"] == "1700000000000:000000:server")
        #expect(response.deletedAt == nil)
    }

    // MARK: - patchCampaign

    @Test
    func patchCampaignRoutesToCampaigns() async throws {
        let captured = CapturedRequest()
        _ = try await withDependencies {
            $0.appConfiguration = .testValue
            $0.appConfiguration.backendBaseURL = { URL(string: "http://localhost:4000/api") }
            $0.httpClient = Self.stubHTTPClient(captured: captured, json: "{ \"appliedFieldClocks\": {} }")
        } operation: {
            try await BackendAPIClient.liveValue.patchCampaign(
                "T",
                "CMP-1",
                ["name": .string("夏季團")],
                ["name": "1700000000000:000000:device-a"]
            )
        }
        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:4000/api/campaigns/CMP-1")
        #expect(request.httpMethod == "PATCH")
    }

    // MARK: - deleteEntity

    @Test
    func deleteEntitySendsDeleteWithToken() async throws {
        let captured = CapturedRequest()
        try await withDependencies {
            $0.appConfiguration = .testValue
            $0.appConfiguration.backendBaseURL = { URL(string: "http://localhost:4000/api") }
            $0.httpClient = Self.stubHTTPClient(captured: captured, json: "{}")
        } operation: {
            try await BackendAPIClient.liveValue.deleteEntity("DTOKEN", "orders", "BL-999")
        }
        let request = try #require(captured.request)
        #expect(request.url?.absoluteString == "http://localhost:4000/api/orders/BL-999")
        #expect(request.httpMethod == "DELETE")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer DTOKEN")
    }
}

// MARK: - CapturedRequest

/// 攔截到的 `URLRequest` 的執行緒安全容器 (`@Sendable` 閉包跨 actor 寫入、測試讀回)
///
/// 不依賴 `ConcurrencyExtras.LockIsolated` (該型別在測試 target 有 transitive 連結 flaky)，
/// 改用 `NSLock` 自封 `@unchecked Sendable`
final class CapturedRequest: @unchecked Sendable {

    // MARK: - Data Properties

    /// 內部鎖
    private let lock = NSLock()

    /// 受鎖保護的請求儲存
    private var stored: URLRequest?

    // MARK: - Computed Properties

    /// 攔截到的請求 (執行緒安全讀寫)
    var request: URLRequest? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

// MARK: - Static Method

private extension BackendAPIClientTests {

    /// 攔截 `URLRequest` 並回傳固定 JSON 的 ``HTTPClient`` (200)
    /// - Parameters:
    ///   - captured: 捕捉到的請求 (供斷言)
    ///   - json: 回應 JSON 字串
    /// - Returns: 注入用的 ``HTTPClient``
    static func stubHTTPClient(captured: CapturedRequest, json: String) -> HTTPClient {
        HTTPClient(
            data: { request in
                captured.request = request
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (Data(json.utf8), response)
            },
            stream: { _ in
                throw APIError.transport(message: "未使用 stream")
            }
        )
    }

    /// 取 `URLRequest` 的 body (處理 `httpBodyStream` 的情形)
    /// - Parameter request: 來源請求
    /// - Returns: body 位元組；無 body 時為 nil
    static func requestBody(_ request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
