//
//  CurrencyMetadataRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 幣別 metadata repository 可能拋出的錯誤
enum CurrencyMetadataRepositoryError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// ExchangeRate-API 失敗
    case api(APIError)
    
    /// 本機幣別快取失敗
    case persistence(CurrencyMetadataPersistenceError)
    
    // MARK: - Computed Properties
    
    /// 顯示底層錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .api(error):
            error.localizedDescription
        case let .persistence(error):
            error.localizedDescription
        }
    }
}

/// ExchangeRate-API 支援幣別主檔的依賴介面
struct CurrencyMetadataRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前 cache 中所有 ISO 4217 code，已排序
    /// - Returns: 已排序的支援幣別代碼
    /// - Throws: API 或本機快取失敗時拋出 ``CurrencyMetadataRepositoryError``
    var fetchCodes: @Sendable () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode]
    
    /// Cache 過期或不存在時重新拉取並寫回非空結果
    /// - Parameter ttl: 判斷 cache 是否過期的存活時間門檻
    /// - Returns: `true` 表示實際做了 refresh、`false` 表示尚在 TTL 內未動作
    /// - Throws: API 或本機快取失敗時拋出 ``CurrencyMetadataRepositoryError``
    var refreshIfStale: @Sendable (_ ttl: TimeInterval) async throws(CurrencyMetadataRepositoryError) -> Bool
    
    /// 強制重新拉取並覆寫 cache
    /// - Throws: API 或本機快取失敗時拋出 ``CurrencyMetadataRepositoryError``
    var forceRefresh: @Sendable () async throws(CurrencyMetadataRepositoryError) -> Void
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
            fetchCodes: { () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                let persistence = await Self.makePersistence(container: container)
                let codes = try await Self.mapPersistence { () async throws(PersistenceError) -> [String] in
                    try await persistence.fetchAllCodes()
                }
                return codes.map { CurrencyCode(rawValue: $0) }
            },
            refreshIfStale: { (ttl: TimeInterval) async throws(CurrencyMetadataRepositoryError) -> Bool in
                let persistence = await Self.makePersistence(container: container)
                let latest = try await Self.mapPersistence { () async throws(PersistenceError) -> Date? in
                    try await persistence.latestUpdate()
                }
                if let latest, now().timeIntervalSince(latest) < ttl {
                    return false
                }
                let codes = try await Self.mapAPI { () async throws(APIError) -> [String] in
                    try await client.fetchSupportedCodes()
                }
                try await Self.mapCurrencyPersistence { () async throws(CurrencyMetadataPersistenceError) in
                    try await persistence.replace(codes: codes, at: now())
                }
                return true
            },
            forceRefresh: { () async throws(CurrencyMetadataRepositoryError) in
                let persistence = await Self.makePersistence(container: container)
                let codes = try await Self.mapAPI { () async throws(APIError) -> [String] in
                    try await client.fetchSupportedCodes()
                }
                try await Self.mapCurrencyPersistence { () async throws(CurrencyMetadataPersistenceError) in
                    try await persistence.replace(codes: codes, at: now())
                }
            }
        )
    }
}

// MARK: - Private Method

private extension CurrencyMetadataRepository {
    
    /// 將持久化基礎錯誤包成 repository error
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 失敗時拋出 ``CurrencyMetadataRepositoryError``
    static func mapPersistence<T>(
        _ operation: () async throws(PersistenceError) -> T
    ) async throws(CurrencyMetadataRepositoryError) -> T {
        do {
            return try await operation()
        } catch {
            throw .persistence(.storage(error))
        }
    }
    
    /// 將 API 錯誤包成 repository error
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 失敗時拋出 ``CurrencyMetadataRepositoryError``
    static func mapAPI<T>(
        _ operation: () async throws(APIError) -> T
    ) async throws(CurrencyMetadataRepositoryError) -> T {
        do {
            return try await operation()
        } catch {
            throw .api(error)
        }
    }
    
    /// 將幣別快取 domain error 包成 repository error
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 失敗時拋出 ``CurrencyMetadataRepositoryError``
    static func mapCurrencyPersistence<T>(
        _ operation: () async throws(CurrencyMetadataPersistenceError) -> T
    ) async throws(CurrencyMetadataRepositoryError) -> T {
        do {
            return try await operation()
        } catch {
            throw .persistence(error)
        }
    }
    
    /// 建立 CurrencyMetadataPersistence
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
    
    /// Preview 使用記憶體資料庫與固定匯率
    nonisolated static let previewValue: CurrencyMetadataRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return CurrencyMetadataRepository.live(container: container, client: .previewValue)
    }()
    
    /// 測試預設回空清單；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CurrencyMetadataRepository(
        fetchCodes: { CurrencyCode.defaults },
        refreshIfStale: { _ in false },
        forceRefresh: {}
    )
}
