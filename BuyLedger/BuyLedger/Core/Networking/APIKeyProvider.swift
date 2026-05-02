//
//  APIKeyProvider.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 集中提供各個外部 API 所需的金鑰。
///
/// 實作策略：先從 `Info.plist` 讀（建議透過 `Config.xcconfig` 注入並加入 `.gitignore`），讀不到再回 `nil`。
/// 上層 client 收到 `nil` 時應該拋 ``APIError/invalidKey``，UI 顯示「請設定 API key」並提供入口給使用者輸入。
struct APIKeyProvider: Sendable {

    // MARK: - Dependency Properties

    /// 取得 ExchangeRate-API 的 API key；若未設定則回 `nil`。
    var exchangeRateAPIKey: @Sendable () -> String?
}

extension APIKeyProvider: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時從 `Bundle.main.infoDictionary` 讀取 `EXCHANGE_RATE_API_KEY`。
    nonisolated static let liveValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: {
            let raw = Bundle.main.object(forInfoDictionaryKey: "EXCHANGE_RATE_API_KEY") as? String
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let trimmed, !trimmed.isEmpty, trimmed != "$(EXCHANGE_RATE_API_KEY)" else {
                return nil
            }
            return trimmed
        }
    )

    /// 測試預設不提供 key；要驗證 happy path 的測試應自行 inject 一個假 key。
    nonisolated static let testValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: { nil }
    )

    /// SwiftUI Preview 用 stub key，避免真的觸發 API call。
    nonisolated static let previewValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: { "preview-stub-key" }
    )
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// API 金鑰提供者。
    var apiKeyProvider: APIKeyProvider {
        get { self[APIKeyProvider.self] }
        set { self[APIKeyProvider.self] = newValue }
    }
}
