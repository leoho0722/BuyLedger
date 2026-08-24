//
//  AppConfiguration.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import ComposableArchitecture
import Foundation

/// 集中提供 App 的環境設定：兩把外部 API key
struct AppConfiguration: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 取得 ExchangeRate-API 的 API key；若未設定則回 `nil`
    /// - Returns: API key，未設定時為 `nil`
    var exchangeRateAPIKey: @Sendable () -> String?
    
    /// 取得 Ollama Cloud 的 API key；若未設定則回 `nil`
    /// - Returns: API key，未設定時為 `nil`
    var ollamaAPIKey: @Sendable () -> String?
}

// MARK: - Internal Method

extension AppConfiguration {
    
    /// 將 `Info.plist` 取回的原始字串正規化。
    /// - Parameters:
    ///   - raw: 從 `Bundle.main.object(forInfoDictionaryKey:)` 取回的原始值
    ///   - placeholder: build setting 的佔位字串；原值等於它表示未注入
    /// - Returns: 有效字串，或在未設定時回 `nil`
    nonisolated static func normalize(_ raw: String?, placeholder: String = "") -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != placeholder else {
            return nil
        }
        return trimmed
    }
}

// MARK: - Dependency Values

extension AppConfiguration: DependencyKey {
    
    /// App 執行時從 `Bundle.main.infoDictionary` 讀取各設定值
    nonisolated static let liveValue = AppConfiguration(
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
    
    /// 測試預設不提供任何設定；要驗證 happy path 的測試應自行 inject
    nonisolated static let testValue = AppConfiguration(
        exchangeRateAPIKey: { nil },
        ollamaAPIKey: { nil }
    )
    
    /// Preview 使用固定設定
    nonisolated static let previewValue = AppConfiguration(
        exchangeRateAPIKey: { "preview-stub-key" },
        ollamaAPIKey: { "preview-stub-key" }
    )
}

// MARK: - DependencyValues Accessor

extension DependencyValues {
    
    /// App 環境設定提供者
    var appConfiguration: AppConfiguration {
        get { self[AppConfiguration.self] }
        set { self[AppConfiguration.self] = newValue }
    }
}
