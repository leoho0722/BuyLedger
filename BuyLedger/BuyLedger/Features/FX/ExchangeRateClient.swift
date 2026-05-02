//
//  ExchangeRateClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 高階 client：對 BuyLedger 隱藏 ExchangeRate-API 的 URL 細節。
///
/// 內部組合 ``HTTPClient`` 與 ``APIKeyProvider``。失敗時會 throw ``APIError``，由 Reducer 決定 UI 呈現。
struct ExchangeRateClient: Sendable {

    // MARK: - Dependency Properties

    /// 抓取指定基準幣別的最新匯率快照。
    var fetchLatest: @Sendable (_ base: CurrencyCode) async throws -> FxRateSnapshot
}

extension ExchangeRateClient: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時透過 ``HTTPClient`` 與 ``APIKeyProvider`` 真實打 API。
    nonisolated static let liveValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { base in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.apiKeyProvider) var apiKeyProvider

            guard let key = apiKeyProvider.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }

            let urlString = "https://v6.exchangerate-api.com/v6/\(key)/latest/\(base.rawValue)"
            guard let url = URL(string: urlString) else {
                throw APIError.transport(message: "URL 組合失敗：\(urlString)")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15

            let (data, response) = try await httpClient.data(request)

            guard 200...299 ~= response.statusCode else {
                throw APIError.http(statusCode: response.statusCode)
            }

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
        }
    )

    /// 測試預設拋出 transport 錯誤；具體測試以 `withDependencies` 注入 stub。
    nonisolated static let testValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { _ in
            throw APIError.transport(message: "ExchangeRateClient.testValue.fetchLatest 被呼叫；請於測試中注入。")
        }
    )

    /// SwiftUI Preview 直接回 fallback 快照。
    nonisolated static let previewValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { _ in FxRateSnapshot.fallback }
    )
}

extension DependencyValues {

    // MARK: - Dependency Values

    /// 匯率 API client。
    var exchangeRateClient: ExchangeRateClient {
        get { self[ExchangeRateClient.self] }
        set { self[ExchangeRateClient.self] = newValue }
    }
}

// MARK: - Response DTO

/// `https://v6.exchangerate-api.com/v6/{KEY}/latest/{BASE}` 的回應 schema。
///
/// 即使 HTTP 200，`result` 也可能是 `"error"`，此時 `error_type` 會帶上具體類別。`Decodable` 全欄位都標 optional 以容錯不同情境。
struct ExchangeRateLatestResponse: Decodable, Sendable {

    // MARK: - Data Properties

    /// API 回應狀態（"success" / "error"）。
    let result: String

    /// 錯誤類別（僅 result == "error" 時才存在）。
    let errorType: String?

    /// 報價時間 UNIX timestamp。
    let timeLastUpdateUnix: TimeInterval?

    /// 基準幣別。
    let baseCode: String?

    /// 各目標幣別的匯率。
    let conversionRates: [String: Double]?

    // MARK: - CodingKeys

    /// 把 API 的 snake_case 欄位映射成 camelCase 屬性。
    enum CodingKeys: String, CodingKey {
        case result
        case errorType = "error-type"
        case timeLastUpdateUnix = "time_last_update_unix"
        case baseCode = "base_code"
        case conversionRates = "conversion_rates"
    }

    // MARK: - View Method

    /// 把 DTO 轉成領域層 ``FxRateSnapshot``，僅保留 ``CurrencyCode`` 認得的幣別。
    /// - Parameter base: 請求時使用的基準幣別。
    /// - Returns: 對應的快照。
    func toSnapshot(base: CurrencyCode) -> FxRateSnapshot {
        let rawRates = conversionRates ?? [:]
        var converted: [CurrencyCode: Decimal] = [:]
        for (key, value) in rawRates {
            if let currency = CurrencyCode(rawValue: key) {
                converted[currency] = Decimal(value)
            }
        }

        let date: Date = {
            if let unix = timeLastUpdateUnix {
                return Date(timeIntervalSince1970: unix)
            }
            return Date()
        }()

        return FxRateSnapshot(date: date, base: base, rates: converted)
    }
}
