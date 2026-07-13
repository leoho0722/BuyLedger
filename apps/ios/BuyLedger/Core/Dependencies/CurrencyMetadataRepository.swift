//
//  CurrencyMetadataRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// ExchangeRate-API 支援幣別主檔的依賴介面
struct CurrencyMetadataRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前 cache 中所有 ISO 4217 code，已排序
    var fetchCodes: @Sendable () async throws -> [CurrencyCode]

    /// 若 cache 過期 (超過給定 TTL 或從未寫過)，打 API 重新拉取並寫回 cache
    /// - Parameter ttl: 判斷 cache 是否過期的存活時間門檻
    /// - Returns: `true` 表示實際做了 refresh、`false` 表示尚在 TTL 內未動作
    var refreshIfStale: @Sendable (_ ttl: TimeInterval) async throws -> Bool

    /// 強制重新拉取並覆寫 cache (不檢查 TTL)，供使用者主動點「重試載入」時呼叫
    var forceRefresh: @Sendable () async throws -> Void
}

// MARK: - Internal Method

extension CurrencyMetadataRepository {

    /// 以指定的 SwiftData ``ModelContainer`` 與 API client 建立 repository
    /// - Parameters:
    ///   - container: 用於建立背景 actor 的 SwiftData container
    ///   - client: 真正打 ExchangeRate-API 的 client
    ///   - now: 取得「目前時間」用的 closure，方便測試注入固定時間
    /// - Returns: 對應的 ``CurrencyMetadataRepository`` 實例
    nonisolated static func live(
        container: ModelContainer,
        client: ExchangeRateClient,
        now: @Sendable @escaping () -> Date = { Date() }
    ) -> CurrencyMetadataRepository {
        CurrencyMetadataRepository(
            fetchCodes: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAllCodes().map { CurrencyCode(rawValue: $0) }
            },
            refreshIfStale: { ttl in
                let persistence = await Self.makePersistence(container: container)
                if let latest = try await persistence.latestUpdate(),
                   now().timeIntervalSince(latest) < ttl {
                    return false
                }
                let codes = try await client.fetchSupportedCodes()
                try await persistence.replace(codes: codes, at: now())
                return true
            },
            forceRefresh: {
                let persistence = await Self.makePersistence(container: container)
                let codes = try await client.fetchSupportedCodes()
                try await persistence.replace(codes: codes, at: now())
            }
        )
    }
}

// MARK: - Private Method

private extension CurrencyMetadataRepository {

    /// 在 main actor 上實例化 ``CurrencyMetadataPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``CurrencyMetadataPersistence`` 實例
    static func makePersistence(container: ModelContainer) async -> CurrencyMetadataPersistence {
        await MainActor.run {
            CurrencyMetadataPersistence(modelContainer: container)
        }
    }
}

// MARK: - Dependency Values

extension CurrencyMetadataRepository: DependencyKey {

    /// App 執行時使用共用 SwiftData container 與 live ``ExchangeRateClient``
    nonisolated static let liveValue: CurrencyMetadataRepository = CurrencyMetadataRepository.live(
        container: PersistenceContainer.shared,
        client: .liveValue
    )

    /// Preview 使用 in-memory container；refresh 走 ``ExchangeRateClient/previewValue``，回傳 ``CurrencyCode/defaults``
    nonisolated static let previewValue: CurrencyMetadataRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return CurrencyMetadataRepository.live(container: container, client: .previewValue)
    }()

    /// 測試預設回空清單；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CurrencyMetadataRepository(
        fetchCodes: { CurrencyCode.defaults },
        refreshIfStale: { _ in false },
        forceRefresh: { }
    )
}
