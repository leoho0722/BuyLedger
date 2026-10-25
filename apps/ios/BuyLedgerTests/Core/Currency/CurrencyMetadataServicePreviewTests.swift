//
//  CurrencyMetadataServicePreviewTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/23.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `CurrencyMetadataService` 的單元測試，涵蓋 Preview 環境的預置快取
struct CurrencyMetadataServicePreviewTests {

    /// 驗證 Preview 讀取幣別時，回傳預先放入的預設幣別，並依代碼的自然排序排列
    ///
    /// - Throws: 讀取快取失敗時丟出持久化讀取錯誤
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

    /// 驗證 Preview 快取仍在七天期限內時，不重新抓取，也不讀取 API 金鑰或發出請求
    ///
    /// - Throws: 讀取快取失敗時丟出持久化讀取錯誤
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
