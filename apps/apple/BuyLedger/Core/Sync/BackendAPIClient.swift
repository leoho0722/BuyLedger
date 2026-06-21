//
//  BackendAPIClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import ComposableArchitecture
import Foundation

/// 後端 API 客戶端依賴。跨裝置同步啟用時，iOS 把本機變更以 partial patch (僅變更欄位 +
/// 每欄位 HLC) 推送後端 (帶 Bearer Firebase ID token)；後端逐欄合併、回傳每欄位權威時鐘。
/// 讀取走 Firestore 投影 (見 ``CloudSync``)，故此 client 僅負責寫入。
struct BackendAPIClient: Sendable {

    // MARK: - Dependency Properties

    /// PATCH 一筆訂單的變更欄位；回傳每個被 patch 欄位的權威時鐘 (供清除 DIRTY)。
    var patchOrder: @Sendable (
        _ idToken: String,
        _ id: String,
        _ changedFields: [String: JSONValue],
        _ fieldClocks: [String: String]
    ) async throws -> OrderPatchResponse

    /// DELETE 一筆訂單；後端硬刪 Postgres 並在 Firestore 寫 tombstone (刪除無條件勝出，毋須帶時鐘)。
    var deleteOrder: @Sendable (_ idToken: String, _ id: String) async throws -> Void
}

// MARK: - Nested Types

extension BackendAPIClient {

    /// PATCH 請求 body。
    struct PatchBody: Encodable, Sendable {

        /// 本次變更的欄位值 (僅含被改動的欄位)。
        let changedFields: [String: JSONValue]

        /// 各變更欄位對應的 HLC 時鐘。
        let fieldClocks: [String: String]
    }

    /// PATCH 回應 (僅取 appliedFieldClocks；合併後的訂單由 Firestore 投影帶回)。
    struct OrderPatchResponse: Decodable, Sendable {

        /// 後端逐欄合併後回傳的每欄位權威時鐘 (供清除 DIRTY)。
        let appliedFieldClocks: [String: String]
    }
}

// MARK: - DependencyKey

extension BackendAPIClient: DependencyKey {

    // MARK: - Dependency Values

    /// 正式實作；透過 ``HTTPClient/send(url:method:headers:body:timeout:)`` 對後端發送 PATCH，base URL 由 ``AppConfiguration`` 提供。
    nonisolated static let liveValue = BackendAPIClient(
        patchOrder: { idToken, id, changedFields, fieldClocks in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let baseURL = appConfiguration.backendBaseURL() else {
                throw APIError.transport(message: "未設定後端 API base URL (BACKEND_API_BASE_URL)。")
            }

            let body = try JSONEncoder().encode(
                PatchBody(changedFields: changedFields, fieldClocks: fieldClocks)
            )
            let data = try await httpClient.send(
                url: baseURL.appendingPathComponent("orders").appendingPathComponent(id),
                method: .patch,
                headers: [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(idToken)",
                ],
                body: body
            )

            do {
                return try JSONDecoder().decode(OrderPatchResponse.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
        },
        deleteOrder: { idToken, id in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let baseURL = appConfiguration.backendBaseURL() else {
                throw APIError.transport(message: "未設定後端 API base URL (BACKEND_API_BASE_URL)。")
            }

            _ = try await httpClient.send(
                url: baseURL.appendingPathComponent("orders").appendingPathComponent(id),
                method: .delete,
                headers: ["Authorization": "Bearer \(idToken)"]
            )
        }
    )

    /// 測試實作；未注入即呼叫時拋錯，強制測試明確以 `withDependencies` 提供行為。
    nonisolated static let testValue = BackendAPIClient(
        patchOrder: { _, _, _, _ in
            throw APIError.transport(
                message: "BackendAPIClient.testValue 被呼叫；請以 withDependencies 注入。"
            )
        },
        deleteOrder: { _, _ in
            throw APIError.transport(
                message: "BackendAPIClient.testValue 被呼叫；請以 withDependencies 注入。"
            )
        }
    )

    /// 預覽實作；沿用 ``testValue`` 避免 Preview 觸發真實網路請求。
    nonisolated static let previewValue = testValue
}
