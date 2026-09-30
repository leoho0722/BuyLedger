//
//  BuyLedgerDatabaseTests+Quarantine.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import Testing

@testable import BuyLedger

// MARK: - Tests

extension BuyLedgerDatabaseTests {

    /// 記憶體資料庫沒有實體 store 檔可搬移，`quarantineStore()` 回傳 `nil`
    ///
    /// - Throws: 隔離失敗時丟出 `PersistenceRecoveryError.directoryCreationFailed` 或 `.fileMoveFailed`
    @Test
    func quarantineStore_記憶體資料庫_回傳空值() async throws {
        // Given
        let database = Self.makeInMemoryDatabase()

        // When
        let quarantinedDirectory = try await database.quarantineStore()

        // Then
        #expect(quarantinedDirectory == nil)
    }

    /// 將指定目錄中的 store 檔移至隔離備份目錄
    ///
    /// - Throws: fixture 建立失敗時丟出底層錯誤；
    ///   隔離目錄建立失敗時丟出 `.directoryCreationFailed`，store 檔搬移失敗時丟出
    ///   `.fileMoveFailed`；fixture 的 store 檔不存在，或隔離結果為 `nil` 時由 `#require`
    ///   丟出測試斷言錯誤
    @Test
    func quarantineStore_指定資料目錄_移動資料庫檔案() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            Self.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = Self.makeDatabase(with: fixture)
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

    /// Application Support 目錄解析失敗時，回報底層錯誤的 domain 與 code
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
        switch error {
        case .directoryResolutionFailed(let underlying):
            let cocoaError = underlying as NSError
            #expect(cocoaError.domain == NSCocoaErrorDomain)
            #expect(cocoaError.code == NSFileNoSuchFileError)

        case .directoryCreationFailed, .fileMoveFailed:
            Issue.record("預期 Application Support 目錄解析失敗")
        }
    }
}
