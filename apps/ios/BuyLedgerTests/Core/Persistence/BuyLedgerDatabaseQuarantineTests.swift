//
//  BuyLedgerDatabaseQuarantineTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

/// `BuyLedgerDatabase` 的單元測試，涵蓋 `quarantineStore()` 將 store 檔搬到隔離備份目錄
struct BuyLedgerDatabaseQuarantineTests {

    /// 驗證記憶體資料庫沒有實體 store 檔可搬移，`quarantineStore()` 回傳 `nil`
    ///
    /// - Throws: 建立隔離目錄或搬移資料庫檔案失敗時丟出復原錯誤
    @Test
    func quarantineStore_記憶體資料庫_回傳空值() async throws {
        // Given
        let database = BuyLedgerDatabaseTestSupport.makeInMemoryDatabase()

        // When
        let quarantinedDirectory = try await database.quarantineStore()

        // Then
        #expect(quarantinedDirectory == nil)
    }

    /// 驗證 `quarantineStore()` 把指定目錄中的 store 檔移至隔離目錄，原位置不再有該檔
    ///
    /// - Throws: 建立測試資料、隔離目錄或搬移資料庫檔案失敗時丟出錯誤；原始檔不存在或沒有回傳隔離結果時丟出測試斷言錯誤
    @Test
    func quarantineStore_指定資料目錄_移動資料庫檔案() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let fileManager = FileManager.default
        let storeURL = fixture.directoryURL.appendingPathComponent("BuyLedger.store")
        try #require(fileManager.fileExists(atPath: storeURL.path))

        // When
        let actualDirectory = try await database.quarantineStore()

        // Then
        let quarantinedDirectory = try #require(actualDirectory)
        #expect(!fileManager.fileExists(atPath: storeURL.path))
        let quarantinedStoreURL = quarantinedDirectory.appendingPathComponent("BuyLedger.store")
        #expect(fileManager.fileExists(atPath: quarantinedStoreURL.path))
    }

    /// 驗證 Application Support 目錄解析失敗時，丟出 `.directoryResolutionFailed`，且保留底層錯誤的網域與代碼
    ///
    /// - Throws: 沒有捕捉到錯誤時由 `#require` 丟出測試斷言錯誤
    @Test
    func quarantineStore_ApplicationSupport解析失敗_保留底層錯誤() async throws {
        // Given
        let modelContainer = TestContainerCreationLock.withLock {
            PersistenceContainer.makeInMemory(for: .testing)
        }
        let database = BuyLedgerDatabase(
            modelContainer: modelContainer,
            storeLocation: .applicationSupport(
                resolveDirectory: {
                    throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
                }
            )
        )
        var actualError: PersistenceRecoveryError?

        // When
        do {
            _ = try await database.quarantineStore()
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        let actualUnderlying: (any Error & Sendable)?
        switch error {
        case .directoryResolutionFailed(let underlying):
            actualUnderlying = underlying

        case .directoryCreationFailed, .fileMoveFailed:
            actualUnderlying = nil
        }
        let cocoaError = try #require(actualUnderlying) as NSError
        #expect(cocoaError.domain == NSCocoaErrorDomain)
        #expect(cocoaError.code == NSFileNoSuchFileError)
    }
}
