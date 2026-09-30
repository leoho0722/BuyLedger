//
//  CurrencyMetadataServiceTests+SaveFailure.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/30.
//

import CoreData
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension CurrencyMetadataServiceTests {

    /// 快取過期後寫入失敗會丟出持久化儲存錯誤而不是 API 錯誤，底層錯誤網域與代碼與 SwiftData 一致，舊快取原樣保留
    ///
    /// - Throws: fixture 建立失敗時丟出底層檔案或 SwiftData 錯誤；seed 失敗時丟出
    ///   `.storage(.saveFailed(underlying:))`；HTTP response fixture 建立失敗、`refreshIfStale`
    ///   沒有丟出錯誤，或錯誤不是 `.persistence(.storage(.saveFailed(underlying:)))` 時由
    ///   `#require` 丟出測試斷言錯誤；讀回快取失敗時丟出
    ///   `.persistence(.storage(.fetchFailed(underlying:)))`
    @Test
    func refreshIfStale_快取寫入失敗_丟出持久化儲存錯誤並保留舊快取() async throws {
        // Given
        let fixture = try Self.makeCacheDiskFixture()
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTests.makeDatabase(with: fixture)
        let cachedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let now = Date(timeIntervalSince1970: 1_700_000_100)
        try await Self.seedCache(["TWD", "USD"], at: cachedAt, in: database)
        let responseJSON = #"{"result":"success","supported_codes":[["JPY","Japanese Yen"]]}"#
        let responseBody = Data(responseJSON.utf8)
        let httpClient = MockHTTPClient()
        httpClient.dataResult = .success(try Self.makeHTTPResponse(body: responseBody))
        let mock = MockBuyLedgerDatabase(database: database)
        mock.mode = .saveFailureAfterBody
        let failingService = Self.makeService(
            database: mock,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: now
        )
        let readService = Self.makeService(
            database: database,
            httpClient: httpClient,
            apiKey: "network-test-key",
            now: now
        )
        var actualError: CurrencyMetadataServiceError?

        // When
        do throws(CurrencyMetadataServiceError) {
            _ = try await failingService.refreshIfStale(0)
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualUnderlying: (any Error & Sendable)?
        switch error {
        case .persistence(.storage(.saveFailed(let underlying))):
            actualUnderlying = underlying

        case .persistence(.storage(.fetchFailed)), .persistence(.emptyCodeList), .api,
                .persistence(.storage(.containerCreationFailed)):
            actualUnderlying = nil
        }
        let underlying = try #require(actualUnderlying) as NSError
        #expect(underlying.domain == NSCocoaErrorDomain)
        #expect(underlying.code == NSValidationRelationshipExceedsMaximumCountError)
        let remainingCodes = try await readService.fetchCodes()
        #expect(remainingCodes == [CurrencyCode(rawValue: "TWD"), .usd])
    }
}

// MARK: - Private Method

private extension CurrencyMetadataServiceTests {

    /// 建立含幣別快取與探測模型的暫存磁碟 store，供 `.saveFailureAfterBody` 觸發真的儲存失敗
    ///
    /// - Returns: 含暫存容器與目錄的 fixture
    /// - Throws: 暫存目錄或 `ModelContainer` 建立失敗時丟出底層 API 錯誤
    static func makeCacheDiskFixture() throws -> ResidueProbeModels.DiskFixture {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "BuyLedgerCurrencyCacheProbe-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let schema = Schema([
            CurrencyMetadataRecord.self,
            ResidueProbeModels.ResidueProbeParent.self,
            ResidueProbeModels.ResidueProbeChild.self,
        ])
        let configuration = ModelConfiguration(
            url: ResidueProbeModels.storeURL(in: directoryURL),
            cloudKitDatabase: .none
        )
        let container = try TestContainerCreationLock.withLock {
            try ModelContainer(for: schema, configurations: [configuration])
        }
        return ResidueProbeModels.DiskFixture(container: container, directoryURL: directoryURL)
    }
}
