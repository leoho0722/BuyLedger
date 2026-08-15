//
//  ExchangeRateClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import ComposableArchitecture
import Foundation

/// 提供 BuyLedger 取得最新匯率與支援幣別代碼的 ExchangeRate-API client
struct ExchangeRateClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 抓取指定基準幣別的最新匯率快照
    /// - Parameter base: 基準幣別
    /// - Returns: 指定基準幣別的最新匯率快照
    /// - Throws: API 請求或回應解析失敗時拋出 ``APIError``
    var fetchLatest: @Sendable (_ base: CurrencyCode) async throws(APIError) -> FxRateSnapshot
    
    /// 抓取 ExchangeRate-API 目前支援的所有 ISO 4217 幣別代碼
    /// - Returns: 支援的 ISO 4217 幣別代碼
    /// - Throws: API 請求或回應解析失敗時拋出 ``APIError``
    var fetchSupportedCodes: @Sendable () async throws(APIError) -> [String]
}

// MARK: - Dependency Values

extension ExchangeRateClient: DependencyKey {
    
    /// App 執行時透過 ``HTTPClient`` 與 ``AppConfiguration`` 真實打 API
    nonisolated static let liveValue: ExchangeRateClient = ExchangeRateClient(
        fetchLatest: { (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration
            @Dependency(\.date) var date
            
            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }
            
            // 拒絕含控制字元的 header 值。
            guard !key.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
                throw APIError.transport(message: "URL 組合失敗。")
            }
            
            let urlString = "https://v6.exchangerate-api.com/v6/latest/\(base.rawValue)"
            guard let url = URL(string: urlString) else {
                throw APIError.transport(message: "URL 組合失敗。")
            }
            
            let data = try await httpClient.send(
                url: url,
                headers: ["Authorization": "Bearer \(key)"],
                timeout: 15
            )
            
            let decoded: ExchangeRateLatestResponse
            do {
                decoded = try JSONDecoder().decode(ExchangeRateLatestResponse.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
            
            guard decoded.result == "success" else {
                throw ExchangeRateClient.serviceError(
                    result: decoded.result,
                    errorType: decoded.errorType
                )
            }
            
            return decoded.toSnapshot(base: base, fallbackDate: date.now)
        },
        fetchSupportedCodes: { () async throws(APIError) -> [String] in
            @Dependency(\.httpClient) var httpClient
            @Dependency(\.appConfiguration) var appConfiguration
            
            guard let key = appConfiguration.exchangeRateAPIKey() else {
                throw APIError.invalidKey
            }
            
            // 拒絕含控制字元的 header 值。
            guard !key.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
                throw APIError.transport(message: "URL 組合失敗。")
            }
            
            let urlString = "https://v6.exchangerate-api.com/v6/codes"
            guard let url = URL(string: urlString) else {
                throw APIError.transport(message: "URL 組合失敗。")
            }
            
            let data = try await httpClient.send(
                url: url,
                headers: ["Authorization": "Bearer \(key)"],
                timeout: 15
            )
            
            let decoded: ExchangeRateCodesResponse
            do {
                decoded = try JSONDecoder().decode(ExchangeRateCodesResponse.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
            
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
            throw APIError.transport(
                message: "ExchangeRateClient.testValue.fetchLatest 被呼叫；請於測試中注入。"
            )
        },
        fetchSupportedCodes: { () async throws(APIError) -> [String] in
            throw APIError.transport(
                message: "ExchangeRateClient.testValue.fetchSupportedCodes 被呼叫；請於測試中注入。"
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
    
    /// 將 ExchangeRate-API 的服務結果映射成單一 ``APIError`` 分類
    /// - Parameters:
    ///   - result: ExchangeRate-API 回傳的結果
    ///   - errorType: ExchangeRate-API 回傳的錯誤代碼
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
