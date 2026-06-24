//
//  BackendAPIClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import ComposableArchitecture
import Foundation

/// 後端 API 客戶端依賴；僅負責寫入 (partial patch，帶 Bearer Firebase ID token)，
/// 讀取走 Firestore 投影 (見 ``CloudSync``)
///
/// 照片以 base64 承載於 `changedFields.photos`；client 絕不上傳 Storage (後端維持 Storage 唯一寫入方)
struct BackendAPIClient: Sendable {

    // MARK: - Dependency Properties

    /// PATCH 一筆訂單的變更欄位；回傳每個被 patch 欄位的權威時鐘 (供清除 DIRTY)
    var patchOrder: @Sendable (
        _ idToken: String,
        _ id: String,
        _ changedFields: [String: JSONValue],
        _ fieldClocks: [String: String]
    ) async throws -> PatchResponse

    /// PATCH 一筆開團的變更欄位；回傳每個被 patch 欄位的權威時鐘
    var patchCampaign: @Sendable (
        _ idToken: String,
        _ id: String,
        _ changedFields: [String: JSONValue],
        _ fieldClocks: [String: String]
    ) async throws -> PatchResponse

    /// DELETE 一筆實體 (依 collection 路由 orders / campaigns)；刪除無條件勝出，毋須帶時鐘
    var deleteEntity: @Sendable (
        _ idToken: String,
        _ collection: String,
        _ id: String
    ) async throws -> Void
}

// MARK: - Nested Types

extension BackendAPIClient {

    /// PATCH 請求 body (對齊後端契約 `{ id, changedFields, fieldClocks }`)
    struct PatchBody: Encodable, Sendable {

        /// 實體 id (client 生成 UUID；後端對缺 id 自動建立)
        let id: String

        /// 本次變更的欄位值 (僅含被改動的欄位；photos 為 base64)
        let changedFields: [String: JSONValue]

        /// 各變更欄位對應的 HLC 時鐘
        let fieldClocks: [String: String]
    }

    /// PATCH 回應；``appliedFieldClocks`` 供 DIRTY 對帳，``deletedAt`` 反映 tombstone，
    /// ``orderData`` 為後端權威完整列供 reconcile 套回敗方 / replay 欄位
    struct PatchResponse: Decodable, Sendable {

        /// 後端逐欄合併後回傳的每欄位權威時鐘 (供清除 / 採用 DIRTY)
        let appliedFieldClocks: [String: String]

        /// 後端回傳的刪除時間戳；存活時為 nil
        let deletedAt: String?

        /// 後端回傳的權威完整 order DTO 原始欄位字典 (供 reconcile 套回敗方 / replay 欄位)；
        /// 缺時為 nil
        let orderData: [String: JSONValue]?

        // MARK: - Init

        /// 解碼 PATCH 回應；缺欄位一律視為 nil (存活 / 無權威列)
        /// - Parameter decoder: 來源解碼器
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.appliedFieldClocks = try container.decodeIfPresent(
                [String: String].self,
                forKey: .appliedFieldClocks
            ) ?? [:]
            self.deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)
            self.orderData = try container.decodeIfPresent([String: JSONValue].self, forKey: .order)
        }

        /// 直接建立 (供測試 / 內部使用)
        /// - Parameters:
        ///   - appliedFieldClocks: 每欄位權威 HLC
        ///   - deletedAt: 刪除時間戳；存活為 nil
        ///   - orderData: 後端權威完整 order DTO 原始欄位字典；無則 nil
        init(
            appliedFieldClocks: [String: String],
            deletedAt: String? = nil,
            orderData: [String: JSONValue]? = nil
        ) {
            self.appliedFieldClocks = appliedFieldClocks
            self.deletedAt = deletedAt
            self.orderData = orderData
        }

        // MARK: - CodingKeys

        /// PATCH 回應的編碼鍵
        enum CodingKeys: String, CodingKey {

            /// 後端權威完整 order DTO
            case order

            /// 每欄位權威 HLC
            case appliedFieldClocks

            /// 刪除時間戳
            case deletedAt
        }
    }
}

// MARK: - DependencyKey

extension BackendAPIClient: DependencyKey {

    // MARK: - Dependency Values

    /// 正式實作；經 ``HTTPClient`` 發送 PATCH / DELETE，base URL 由 ``AppConfiguration`` 提供
    nonisolated static let liveValue = BackendAPIClient(
        patchOrder: { idToken, id, changedFields, fieldClocks in
            try await Self.patch(
                collection: "orders",
                idToken: idToken,
                id: id,
                changedFields: changedFields,
                fieldClocks: fieldClocks
            )
        },
        patchCampaign: { idToken, id, changedFields, fieldClocks in
            try await Self.patch(
                collection: "campaigns",
                idToken: idToken,
                id: id,
                changedFields: changedFields,
                fieldClocks: fieldClocks
            )
        },
        deleteEntity: { idToken, collection, id in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let baseURL = appConfiguration.backendBaseURL() else {
                throw APIError.transport(message: "未設定後端 API base URL (BACKEND_API_BASE_URL)。")
            }

            _ = try await httpClient.send(
                url: baseURL.appendingPathComponent(collection).appendingPathComponent(id),
                method: .delete,
                headers: ["Authorization": "Bearer \(idToken)"]
            )
        }
    )

    /// 測試實作；未注入即呼叫時拋錯，強制測試明確以 `withDependencies` 提供行為
    nonisolated static let testValue = BackendAPIClient(
        patchOrder: { _, _, _, _ in
            throw APIError.transport(
                message: "BackendAPIClient.testValue 被呼叫；請以 withDependencies 注入。"
            )
        },
        patchCampaign: { _, _, _, _ in
            throw APIError.transport(
                message: "BackendAPIClient.testValue 被呼叫；請以 withDependencies 注入。"
            )
        },
        deleteEntity: { _, _, _ in
            throw APIError.transport(
                message: "BackendAPIClient.testValue 被呼叫；請以 withDependencies 注入。"
            )
        }
    )

    /// 預覽實作；沿用 ``testValue`` 避免 Preview 觸發真實網路請求
    nonisolated static let previewValue = testValue
}

// MARK: - Private Method

private extension BackendAPIClient {

    /// 共用的 PATCH 實作 (orders / campaigns 同形狀，僅 collection 路由不同)
    /// - Parameters:
    ///   - collection: REST 路徑段 ("orders" / "campaigns")
    ///   - idToken: Firebase ID token (Bearer)
    ///   - id: 實體 id
    ///   - changedFields: 變更欄位值 (photos 為 base64)
    ///   - fieldClocks: 各欄位 HLC
    /// - Returns: 後端 PATCH 回應
    static func patch(
        collection: String,
        idToken: String,
        id: String,
        changedFields: [String: JSONValue],
        fieldClocks: [String: String]
    ) async throws -> PatchResponse {
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.appConfiguration) var appConfiguration

        guard let baseURL = appConfiguration.backendBaseURL() else {
            throw APIError.transport(message: "未設定後端 API base URL (BACKEND_API_BASE_URL)。")
        }

        let body = try JSONEncoder().encode(
            PatchBody(id: id, changedFields: changedFields, fieldClocks: fieldClocks)
        )
        let data = try await httpClient.send(
            url: baseURL.appendingPathComponent(collection).appendingPathComponent(id),
            method: .patch,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(idToken)",
            ],
            body: body
        )

        do {
            return try JSONDecoder().decode(PatchResponse.self, from: data)
        } catch {
            throw APIError.decoding(message: String(describing: error))
        }
    }
}
