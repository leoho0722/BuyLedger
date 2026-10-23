//
//  CurrencyMetadataServicePreviewTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/23.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證幣別主檔 Service 在 Preview 讀取預先放入資料庫的預設幣別
struct CurrencyMetadataServicePreviewTests {

    /// Preview 讀取幣別時拿到預先放入的預設幣別，依代碼排序
    ///
    /// - Throws: 讀取快取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`
    @Test
    func previewValue_讀取幣別_回傳排序後的預設幣別() async throws {
        // Given
        let database = TestContainerCreationLock.withLock {
            BuyLedgerDatabaseKey.previewValue
        }
        let service = withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CurrencyMetadataService.previewValue
        }

        // When
        let codes = try await service.fetchCodes()

        // Then
        #expect(codes == ["CNY", "JPY", "KRW", "TWD", "USD"].map { CurrencyCode(rawValue: $0) })
    }

    /// Preview 檢查快取時預先放入的幣別仍有效，不讀 API 金鑰也不發出請求
    ///
    /// - Throws: 讀取快取失敗時丟出 `.persistence(.storage(.fetchFailed(underlying:)))`
    @Test
    func previewValue_檢查快取_不重新抓取也不發出請求() async throws {
        // Given
        let ttl = 7.0 * 24 * 60 * 60
        let httpClient = MockHTTPClient()
        let configurationStore = MockAppConfigurationStore()
        let database = TestContainerCreationLock.withLock {
            BuyLedgerDatabaseKey.previewValue
        }
        let service = withDependencies {
            $0.buyLedgerDatabase = database
            $0.httpClient = httpClient
            $0.appConfigurationStore = configurationStore
            $0.date = .constant(TestDependencies.fixedNow)
        } operation: {
            CurrencyMetadataService.previewValue
        }

        // When
        let isRefreshed = try await service.refreshIfStale(ttl)

        // Then
        #expect(isRefreshed == false)
        #expect(httpClient.dataCallCount == 0)
        #expect(configurationStore.stringCallCount == 0)
    }
}
