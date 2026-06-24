//
//  AppConfiguration.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import ComposableArchitecture
import Foundation

/// 集中提供 App 的環境設定：兩把外部 API key 與跨裝置同步的後端 API base URL
///
/// 值皆於 build 期注入、App 啟動時自 `Bundle.main.infoDictionary` 讀回：機密的 API key 經 gitignored 的
/// `Config.xcconfig` → `Info.plist` 的 `$(VAR)` 引用注入；非機密的後端位址直接定義於 `Info.plist`
/// 上層 client 收到 `nil` key 時應拋 ``APIError/invalidKey``，UI 顯示「請設定 API key」並提供入口給使用者輸入
struct AppConfiguration: Sendable {

    // MARK: - Dependency Properties

    /// 取得 ExchangeRate-API 的 API key；若未設定則回 `nil`
    var exchangeRateAPIKey: @Sendable () -> String?

    /// 取得 Ollama Cloud 的 API key；若未設定則回 `nil`
    var ollamaAPIKey: @Sendable () -> String?

    /// 取得跨裝置同步的後端 API base URL；若未設定或格式非法則回 `nil`
    var backendBaseURL: @Sendable () -> URL?
}

extension AppConfiguration {

    // MARK: - Static Method

    /// 將 `Info.plist` 取回的原始字串正規化：去除前後空白，並把空字串或「尚未被 `Config.xcconfig` 取代的 `$(VAR)` 佔位」視為「未設定」回 `nil`
    /// - Parameters:
    ///   - raw: 從 `Bundle.main.object(forInfoDictionaryKey:)` 取回的原始值
    ///   - placeholder: 對應 build setting 變數的佔位字串 (例如 `$(OLLAMA_API_KEY)`)；原始值等於它代表 xcconfig 未注入。直接定義於 `Info.plist` 的值無佔位，預設空字串即可
    /// - Returns: 有效字串，或在未設定時回 `nil`
    nonisolated static func normalize(_ raw: String?, placeholder: String = "") -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty, trimmed != placeholder else {
            return nil
        }
        return trimmed
    }
}

extension AppConfiguration: DependencyKey {

    // MARK: - Dependency Values

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
        },
        backendBaseURL: {
            normalize(Bundle.main.object(forInfoDictionaryKey: "BACKEND_API_BASE_URL") as? String)
                .flatMap { URL(string: $0) }
        }
    )

    /// 測試預設不提供任何設定；要驗證 happy path 的測試應自行 inject
    nonisolated static let testValue = AppConfiguration(
        exchangeRateAPIKey: { nil },
        ollamaAPIKey: { nil },
        backendBaseURL: { nil }
    )

    /// SwiftUI Preview 用 stub，避免真的觸發 API call
    nonisolated static let previewValue = AppConfiguration(
        exchangeRateAPIKey: { "preview-stub-key" },
        ollamaAPIKey: { "preview-stub-key" },
        backendBaseURL: { URL(string: "http://localhost:4000/api") }
    )
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// App 環境設定提供者
    var appConfiguration: AppConfiguration {
        get { self[AppConfiguration.self] }
        set { self[AppConfiguration.self] = newValue }
    }
}
