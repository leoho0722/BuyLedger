//
//  ExchangeRateClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 提供 BuyLedger 取得最新匯率與支援幣別代碼的 `ExchangeRate-API` client
struct ExchangeRateClient: Sendable {

    // MARK: - Properties

    /// 抓取指定基準幣別的最新匯率快照
    ///
    /// - Parameter base: 基準幣別
    /// - Returns: 指定基準幣別的最新匯率快照
    /// - Throws: API 請求或回應解析失敗時拋出 ``APIError``
    var fetchLatest: @Sendable (_ base: CurrencyCode) async throws(APIError) -> FxRateSnapshot

    /// 抓取 `ExchangeRate-API` 目前支援的所有 ISO 4217 幣別代碼
    ///
    /// - Returns: 支援的 ISO 4217 幣別代碼
    /// - Throws: API 請求或回應解析失敗時拋出 ``APIError``
    var fetchSupportedCodes: @Sendable () async throws(APIError) -> [String]
}

// MARK: - DependencyKey

extension ExchangeRateClient: DependencyKey {

    /// App 執行時透過 ``HTTPClient`` 與 ``AppConfiguration`` 真實打 API
    nonisolated static let liveValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: {
            (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration
            @Dependency(\.date) var date

            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }

            // 拒絕含控制字元的 header 值。
            guard !key.unicodeScalars.contains(
                where: CharacterSet.controlCharacters.contains
            ) else {
                throw Self.invalidRequestError(diagnosticMessage: "URL 組合失敗。")
            }

            let urlString = "https://v6.exchangerate-api.com/v6/latest/\(base.rawValue)"
            guard let url = URL(string: urlString) else {
                throw Self.invalidRequestError(diagnosticMessage: "URL 組合失敗。")
            }

            let data = try await httpClient.send(
                url: url,
                headers: ["Authorization": "Bearer \(key)"],
                timeout: 15
            )

            let decoded = try httpClient.decode(ExchangeRateLatestResponse.self, from: data)

            guard decoded.result == "success" else {
                throw ExchangeRateClient.serviceError(
                    result: decoded.result,
                    errorType: decoded.errorType
                )
            }

            return decoded.toSnapshot(base: base, fallbackDate: date.now)
        },
        fetchSupportedCodes: {
            () async throws(APIError) -> [String] in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration

            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }

            // 拒絕含控制字元的 header 值。
            guard !key.unicodeScalars.contains(
                where: CharacterSet.controlCharacters.contains
            ) else {
                throw Self.invalidRequestError(diagnosticMessage: "URL 組合失敗。")
            }

            let urlString = "https://v6.exchangerate-api.com/v6/codes"
            guard let url = URL(string: urlString) else {
                throw Self.invalidRequestError(diagnosticMessage: "URL 組合失敗。")
            }

            let data = try await httpClient.send(
                url: url,
                headers: ["Authorization": "Bearer \(key)"],
                timeout: 15
            )

            let decoded = try httpClient.decode(ExchangeRateCodesResponse.self, from: data)

            guard decoded.result == "success" else {
                throw ExchangeRateClient.serviceError(
                    result: decoded.result,
                    errorType: decoded.errorType
                )
            }

            return decoded.supportedCodes?.compactMap { $0.first } ?? []
        }
    )

    /// 測試預設拋出 transport 錯誤；具體測試以 `withDependencies` 注入 stub
    nonisolated static let testValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { (_: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
            throw Self.dependencyNotInjectedError(
                diagnosticMessage: "ExchangeRateClient.testValue.fetchLatest 被呼叫；請於測試中注入。"
            )
        },
        fetchSupportedCodes: { () async throws(APIError) -> [String] in
            throw Self.dependencyNotInjectedError(
                diagnosticMessage: "ExchangeRateClient.testValue.fetchSupportedCodes 被呼叫；請於測試中注入。"
            )
        }
    )

    /// Preview 回傳固定匯率與預設幣別
    nonisolated static let previewValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { _ in FxRateSnapshot.fallback },
        fetchSupportedCodes: { CurrencyCode.defaults.map(\.rawValue) }
    )
}

// MARK: - Private Method

private extension ExchangeRateClient {

    /// networking 層自有的診斷錯誤 domain
    static let networkingErrorDomain = "com.leoho.BuyLedger.networking"

    /// 請求組合失敗的診斷錯誤代碼
    static let invalidRequestCode = 1

    /// 依賴未注入的診斷錯誤代碼
    static let dependencyNotInjectedCode = 2

    /// 建立請求組合失敗的 transport 錯誤
    ///
    /// - Parameter diagnosticMessage: 要提供給診斷使用的錯誤描述
    /// - Returns: 帶 NSError 底層資訊的 transport 錯誤
    static func invalidRequestError(diagnosticMessage: String) -> APIError {
        .transport(
            underlying: NSError(
                domain: networkingErrorDomain,
                code: invalidRequestCode,
                userInfo: [NSLocalizedDescriptionKey: diagnosticMessage]
            )
        )
    }

    /// 建立依賴未注入的 transport 錯誤
    ///
    /// - Parameter diagnosticMessage: 要提供給診斷使用的錯誤描述
    /// - Returns: 帶原始錯誤資訊的 transport 錯誤
    static func dependencyNotInjectedError(diagnosticMessage: String) -> APIError {
        .transport(
            underlying: NSError(
                domain: networkingErrorDomain,
                code: dependencyNotInjectedCode,
                userInfo: [NSLocalizedDescriptionKey: diagnosticMessage]
            )
        )
    }

    /// 將 `ExchangeRate-API` 的服務結果映射成單一 ``APIError`` 分類
    /// - Parameters:
    ///   - result: `ExchangeRate-API` 回傳的結果
    ///   - errorType: `ExchangeRate-API` 回傳的錯誤代碼
    /// - Returns: 對應的 ``APIError``
    static func serviceError(result: String, errorType: String?) -> APIError {
        guard result == "error" else {
            return .apiError(code: "unexpected-result-\(result)")
        }

        switch errorType ?? "unknown" {
        case "invalid-key", "inactive-account":
            return .invalidKey
        case "quota-reached":
            return .quotaExceeded
        case let code:
            return .apiError(code: code)
        }
    }
}
