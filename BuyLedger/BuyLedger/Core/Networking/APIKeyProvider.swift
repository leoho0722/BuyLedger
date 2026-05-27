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
/// 實作策略：先從 `Info.plist` 讀 (建議透過 `Config.xcconfig` 注入並加入 `.gitignore`)，讀不到再回 `nil`。
/// 上層 client 收到 `nil` 時應該拋 ``APIError/invalidKey``，UI 顯示「請設定 API key」並提供入口給使用者輸入。
struct APIKeyProvider: Sendable {

    // MARK: - Dependency Properties

    /// 取得 ExchangeRate-API 的 API key；若未設定則回 `nil`。
    var exchangeRateAPIKey: @Sendable () -> String?

    /// 取得 Ollama Cloud 的 API key；若未設定則回 `nil`。
    var ollamaAPIKey: @Sendable () -> String?
}

extension APIKeyProvider {

    // MARK: - Static Method

    /// 將 `Info.plist` 取回的原始字串正規化：去除前後空白，並把空字串或「尚未被 `Config.xcconfig` 取代的 `$(VAR)` 佔位」視為「未設定」回 `nil`。
    /// - Parameters:
    ///   - raw: 從 `Bundle.main.object(forInfoDictionaryKey:)` 取回的原始值。
    ///   - placeholder: 對應 build setting 變數的佔位字串 (例如 `$(OLLAMA_API_KEY)`)；原始值等於它代表 xcconfig 未注入。
    /// - Returns: 有效的 key，或在未設定時回 `nil`。
    nonisolated static func normalize(_ raw: String?, placeholder: String) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != placeholder else {
            return nil
        }
        return trimmed
    }
}

extension APIKeyProvider: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時從 `Bundle.main.infoDictionary` 讀取各金鑰。
    nonisolated static let liveValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: {
            normalize(
                Bundle.main.object(forInfoDictionaryKey: "EXCHANGE_RATE_API_KEY") as? String,
                placeholder: "$(EXCHANGE_RATE_API_KEY)"
            )
        },
        ollamaAPIKey: {
            normalize(
                Bundle.main.object(forInfoDictionaryKey: "OLLAMA_API_KEY") as? String,
                placeholder: "$(OLLAMA_API_KEY)"
            )
        }
    )

    /// 測試預設不提供 key；要驗證 happy path 的測試應自行 inject 一個假 key。
    nonisolated static let testValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: { nil },
        ollamaAPIKey: { nil }
    )

    /// SwiftUI Preview 用 stub key，避免真的觸發 API call。
    nonisolated static let previewValue: APIKeyProvider = APIKeyProvider(
        exchangeRateAPIKey: { "preview-stub-key" },
        ollamaAPIKey: { "preview-stub-key" }
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
