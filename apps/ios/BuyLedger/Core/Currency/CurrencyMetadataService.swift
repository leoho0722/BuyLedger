//
//  CurrencyMetadataService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 讀取與更新支援幣別主檔的操作入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
struct CurrencyMetadataService: Sendable {

    // MARK: - Properties

    /// 讀取目前快取中的幣別代碼 (如 TWD、USD) 並排序
    ///
    /// - Returns: 已排序的支援幣別代碼
    /// - Throws: 讀取快取失敗時丟出
    ///   `.persistence(.storage(.fetchFailed(underlying:)))`
    var fetchCodes: FetchCodes

    /// 快取過期或不存在時重新取得幣別清單並存回快取，快取仍有效時不重抓
    ///
    /// - Parameter ttl: 判斷快取是否過期的存活時間門檻
    /// - Returns: `true` 表示實際更新、`false` 表示快取仍有效
    /// - Throws: API 失敗時丟出 `.api(.invalidKey)`、`.api(.transport(underlying:))`、
    ///   `.api(.http(statusCode:))`、`.api(.decoding(underlying:))`、`.api(.quotaExceeded)` 或
    ///   `.api(.apiError(code:))`；空清單時丟出 `.persistence(.emptyCodeList)`；
    ///   快取讀取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`；
    ///   快取儲存失敗時丟出 `.persistence(.storage(.saveFailed(underlying:)))`
    var refreshIfStale: RefreshIfStale
}

// MARK: - Nested Types

extension CurrencyMetadataService {

    /// `fetchCodes` 的函式型別
    typealias FetchCodes = @Sendable () async throws(CurrencyMetadataServiceError) -> [CurrencyCode]

    /// `refreshIfStale` 的函式型別
    typealias RefreshIfStale = @Sendable (
        _ ttl: TimeInterval
    ) async throws(CurrencyMetadataServiceError) -> Bool
}

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

    #if DEBUG

    /// Preview 從共用的記憶體資料庫讀取預先放入的預設幣別
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "CurrencyMetadataService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }

    #endif

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

// MARK: - Private Method

private extension CurrencyMetadataService {

    /// 從資料庫讀取並排序快取中的幣別代碼
    ///
    /// - Parameter database: 執行快取讀取的資料庫
    /// - Returns: 已排序的支援幣別代碼
    /// - Throws: 讀取失敗時丟出
    ///   `.persistence(.storage(.fetchFailed(underlying:)))`
    static func loadCodes(
        from database: any BuyLedgerDatabaseProtocol
    ) async throws(CurrencyMetadataServiceError) -> [CurrencyCode] {
        let codes: [String]
        do throws(PersistenceError) {
            codes = try await database.read { context throws(PersistenceError) in
                let records = try PersistenceError.mapFetch {
                    try context.fetch(FetchDescriptor<CurrencyMetadataRecord>())
                }
                return records
                    .map(\.code)
                    .sorted { lhs, rhs in
                        lhs.localizedStandardCompare(rhs) == .orderedAscending
                    }
            }
        } catch {
            throw .persistence(.storage(error))
        }
        return codes.map { CurrencyCode(rawValue: $0) }
    }

    /// 快取過期或不存在時取得支援幣別並替換快取
    ///
    /// - Parameters:
    ///   - ttl: 判斷快取是否過期的存活時間門檻
    ///   - database: 執行快取讀寫的資料庫
    ///   - httpClient: 傳送幣別清單請求的 HTTP client
    ///   - configurationStore: 提供 API 金鑰的設定來源
    ///   - now: 判斷快取時間與標記更新時間的目前時刻
    /// - Returns: `true` 表示實際更新、`false` 表示快取仍有效
    /// - Throws: API 失敗時丟出 `.api(.invalidKey)`、`.api(.transport(underlying:))`、
    ///   `.api(.http(statusCode:))`、`.api(.decoding(underlying:))`、`.api(.quotaExceeded)` 或
    ///   `.api(.apiError(code:))`；空清單時丟出 `.persistence(.emptyCodeList)`；
    ///   快取讀取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`；
    ///   快取儲存失敗時丟出 `.persistence(.storage(.saveFailed(underlying:)))`
    static func refreshCodesIfNeeded(
        ttl: TimeInterval,
        database: any BuyLedgerDatabaseProtocol,
        httpClient: any HTTPClientProtocol,
        configurationStore: any AppConfigurationStoreProtocol,
        now: @Sendable () -> Date
    ) async throws(CurrencyMetadataServiceError) -> Bool {
        let latestUpdate: Date?
        do throws(PersistenceError) {
            latestUpdate = try await database.read { context throws(PersistenceError) in
                var descriptor = FetchDescriptor<CurrencyMetadataRecord>(sortBy: [
                    SortDescriptor(\.lastUpdated, order: .reverse),
                ])
                descriptor.fetchLimit = 1
                return try PersistenceError.mapFetch {
                    try context.fetch(descriptor).first?.lastUpdated
                }
            }
        } catch {
            throw .persistence(.storage(error))
        }

        if let latestUpdate, now().timeIntervalSince(latestUpdate) < ttl {
            return false
        }

        let codes = try await Self.fetchSupportedCodes(
            using: httpClient,
            configurationStore: configurationStore
        )
        do throws(CurrencyMetadataPersistenceError) {
            try await database.write { context throws(CurrencyMetadataPersistenceError) in
                guard !codes.isEmpty else {
                    throw .emptyCodeList
                }

                let records: [CurrencyMetadataRecord]
                do throws(PersistenceError) {
                    records = try PersistenceError.mapFetch {
                        try context.fetch(FetchDescriptor<CurrencyMetadataRecord>())
                    }
                } catch {
                    throw .storage(error)
                }

                for record in records {
                    context.delete(record)
                }

                let lastUpdated = now()
                for code in codes {
                    context.insert(CurrencyMetadataRecord(code: code, lastUpdated: lastUpdated))
                }
            }
        } catch {
            throw .persistence(error)
        }
        return true
    }

    /// 從 ExchangeRate-API 取得原始支援幣別代碼
    ///
    /// - Parameters:
    ///   - httpClient: 傳送幣別清單請求的 HTTP client
    ///   - configurationStore: 提供 API 金鑰的設定來源
    /// - Returns: API 回傳的支援幣別代碼
    /// - Throws: 缺少金鑰，或服務回報金鑰無效、帳號停用時丟出 `.api(.invalidKey)`；
    ///   金鑰含控制字元、URL 無效或傳輸失敗時丟出 `.api(.transport(underlying:))`；
    ///   HTTP 狀態碼非 2xx 時丟出 `.api(.http(statusCode:))`；解碼失敗時丟出
    ///   `.api(.decoding(underlying:))`；配額用盡時丟出 `.api(.quotaExceeded)`；
    ///   其他服務錯誤時丟出 `.api(.apiError(code:))`
    static func fetchSupportedCodes(
        using httpClient: any HTTPClientProtocol,
        configurationStore: any AppConfigurationStoreProtocol
    ) async throws(CurrencyMetadataServiceError) -> [String] {
        do throws(APIError) {
            guard let apiKey = configurationStore.string(
                forKey: ExchangeRateEndpoint.apiKeyConfigurationKey
            ) else {
                throw APIError.invalidKey
            }
            let response = try await ExchangeRateEndpoint.fetch(
                ExchangeRateCodesResponse.self,
                path: "codes",
                apiKey: apiKey,
                using: httpClient
            )
            guard response.result == "success" else {
                throw ExchangeRateEndpoint.serviceError(
                    result: response.result,
                    errorType: response.errorType
                )
            }
            return response.supportedCodes?.compactMap { $0.first } ?? []
        } catch {
            throw .api(error)
        }
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
