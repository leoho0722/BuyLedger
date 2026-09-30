//
//  CurrencyMetadataService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension CurrencyMetadataService: DependencyKey {

    /// 正式 App 使用注入的資料庫、HTTP、設定來源與目前時間；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database、Client、Store 與時間
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        @Dependency(\.httpClient) var httpClient
        @Dependency(\.appConfigurationStore) var configurationStore
        @Dependency(\.date) var date

        return Self(
            fetchCodes: { () throws(CurrencyMetadataServiceError) in
                try await Self.loadCodes(from: database)
            },
            refreshIfStale: { ttl throws(CurrencyMetadataServiceError) in
                try await Self.refreshCodesIfNeeded(
                    ttl: ttl,
                    database: database,
                    httpClient: httpClient,
                    configurationStore: configurationStore,
                    now: {
                        date.now
                    }
                )
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchCodes: unimplemented("CurrencyMetadataService.fetchCodes", placeholder: []),
            refreshIfStale: unimplemented(
                "CurrencyMetadataService.refreshIfStale",
                placeholder: false
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.currencyMetadataService)` 取得的 Currency Metadata Service
    var currencyMetadataService: CurrencyMetadataService {
        get { self[CurrencyMetadataService.self] }
        set { self[CurrencyMetadataService.self] = newValue }
    }
}
