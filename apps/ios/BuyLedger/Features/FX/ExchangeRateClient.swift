//
//  ExchangeRateClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 高階 client：對 BuyLedger 隱藏 ExchangeRate-API 的 URL 細節
///
/// 內部組合 ``HTTPClient`` 與 ``AppConfiguration``。失敗時會 throw ``APIError``，由 Reducer 決定 UI 呈現
struct ExchangeRateClient: Sendable {

    // MARK: - Dependency Properties

    /// 抓取指定基準幣別的最新匯率快照
    /// - Parameter base: 基準幣別
    var fetchLatest: @Sendable (_ base: CurrencyCode) async throws -> FxRateSnapshot

    /// 抓取 ExchangeRate-API 目前支援的所有 ISO 4217 幣別代碼
    var fetchSupportedCodes: @Sendable () async throws -> [String]
}

// MARK: - Dependency Values

extension ExchangeRateClient: DependencyKey {

    /// App 執行時透過 ``HTTPClient`` 與 ``AppConfiguration`` 真實打 API
    nonisolated static let liveValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { base in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }

            let urlString = "https://v6.exchangerate-api.com/v6/\(key)/latest/\(base.rawValue)"
            guard let url = URL(string: urlString) else {
                throw APIError.transport(message: "URL 組合失敗：\(urlString)")
            }

            let data = try await httpClient.send(url: url, timeout: 15)

            let decoded: ExchangeRateLatestResponse
            do {
                decoded = try JSONDecoder().decode(ExchangeRateLatestResponse.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }

            switch decoded.result {
            case "success":
                return decoded.toSnapshot(base: base)
            case "error":
                let code = decoded.errorType ?? "unknown"
                switch code {
                case "invalid-key", "inactive-account":
                    throw APIError.invalidKey
                case "quota-reached":
                    throw APIError.quotaExceeded
                default:
                    throw APIError.apiError(code: code)
                }
            default:
                throw APIError.apiError(code: "unexpected-result-\(decoded.result)")
            }
        },
        fetchSupportedCodes: {
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }

            let urlString = "https://v6.exchangerate-api.com/v6/\(key)/codes"
            guard let url = URL(string: urlString) else {
                throw APIError.transport(message: "URL 組合失敗：\(urlString)")
            }

            let data = try await httpClient.send(url: url, timeout: 15)

            let decoded: ExchangeRateCodesResponse
            do {
                decoded = try JSONDecoder().decode(ExchangeRateCodesResponse.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }

            switch decoded.result {
            case "success":
                return decoded.supportedCodes?.compactMap { $0.first } ?? []
            case "error":
                let code = decoded.errorType ?? "unknown"
                switch code {
                case "invalid-key", "inactive-account":
                    throw APIError.invalidKey
                case "quota-reached":
                    throw APIError.quotaExceeded
                default:
                    throw APIError.apiError(code: code)
                }
            default:
                throw APIError.apiError(code: "unexpected-result-\(decoded.result)")
            }
        }
    )

    /// 測試預設拋出 transport 錯誤；具體測試以 `withDependencies` 注入 stub
    nonisolated static let testValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { _ in
            throw APIError.transport(message: "ExchangeRateClient.testValue.fetchLatest 被呼叫；請於測試中注入。")
        },
        fetchSupportedCodes: {
            throw APIError.transport(message: "ExchangeRateClient.testValue.fetchSupportedCodes 被呼叫；請於測試中注入。")
        }
    )

    /// SwiftUI Preview 直接回 fallback 快照與 default 幣別 code 集
    nonisolated static let previewValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { _ in FxRateSnapshot.fallback },
        fetchSupportedCodes: { CurrencyCode.defaults.map(\.rawValue) }
    )
}

// MARK: - DependencyValues Accessor

extension DependencyValues {

    /// 匯率 API client
    var exchangeRateClient: ExchangeRateClient {
        get { self[ExchangeRateClient.self] }
        set { self[ExchangeRateClient.self] = newValue }
    }
}
