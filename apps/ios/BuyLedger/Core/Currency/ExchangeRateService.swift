//
//  ExchangeRateService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

/// 取得指定基準幣別最新匯率的操作入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct ExchangeRateService: Sendable {

    // MARK: - Properties

    /// 抓取指定基準幣別的最新匯率快照
    ///
    /// - Parameter base: 基準幣別
    /// - Returns: 指定基準幣別的最新匯率快照
    /// - Throws: 缺少金鑰，或服務回報金鑰無效、帳號停用時丟出 `.invalidKey`；
    ///   金鑰含控制字元、URL 無效或傳輸失敗時丟出 `.transport(underlying:)`；
    ///   HTTP 狀態碼非 2xx 時丟出 `.http(statusCode:)`；解碼失敗時丟出 `.decoding(underlying:)`；
    ///   配額用盡時丟出 `.quotaExceeded`；其他服務錯誤時丟出 `.apiError(code:)`
    var fetchLatest: FetchLatest
}

// MARK: - Nested Types

extension ExchangeRateService {

    /// `fetchLatest` 的函式型別
    typealias FetchLatest = @Sendable (
        _ base: CurrencyCode
    ) async throws(APIError) -> FxRateSnapshot
}

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

    #if DEBUG

    /// Preview 使用固定匯率資料
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "ExchangeRateService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            fetchLatest: { _ in FxRateSnapshot.fallback }
        )
    }

    #endif

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchLatest: unimplemented(
                "ExchangeRateService.fetchLatest",
                placeholder: FxRateSnapshot(
                    date: Date(timeIntervalSince1970: 0),
                    base: .twd,
                    rates: [:]
                )
            )
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
