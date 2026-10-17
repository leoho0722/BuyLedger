//
//  ExchangeRateService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension ExchangeRateService: DependencyKey {

    /// 正式 App 使用注入的 HTTP、設定來源與目前時間取得最新匯率；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Client、Store 與時間
    static var liveValue: Self {
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.appConfigurationStore) var configurationStore
        @Dependency(\.date) var date

        return Self(
            fetchLatest: { base throws(APIError) in
                guard let apiKey = configurationStore.string(
                    forKey: ExchangeRateEndpoint.apiKeyConfigurationKey
                ) else {
                    throw APIError.invalidKey
                }
                let response = try await ExchangeRateEndpoint.fetch(
                    ExchangeRateLatestResponse.self,
                    path: "latest/\(base.rawValue)",
                    apiKey: apiKey,
                    using: httpClient
                )
                guard response.result == "success" else {
                    throw ExchangeRateEndpoint.serviceError(
                        result: response.result,
                        errorType: response.errorType
                    )
                }
                return response.toSnapshot(base: base, fallbackDate: date.now)
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchLatest: unimplemented("ExchangeRateService.fetchLatest", placeholder: .fallback)
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.exchangeRateService)` 取得的 Exchange Rate Service
    var exchangeRateService: ExchangeRateService {
        get { self[ExchangeRateService.self] }
        set { self[ExchangeRateService.self] = newValue }
    }
}
