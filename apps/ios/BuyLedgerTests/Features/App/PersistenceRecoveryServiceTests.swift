//
//  PersistenceRecoveryServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `PersistenceRecoveryService` 的單元測試，以磁碟上的 store 檔確認 Service 透過 Database 搬移檔案
struct PersistenceRecoveryServiceTests {

    /// 驗證復原時 Service 透過注入的 Database，把磁碟上的 store 檔移到隔離目錄 Recovered-1，原位置不再有 store 檔
    ///
    /// - Throws: 暫存資料庫建立失敗時丟出底層錯誤；store 檔不存在時 `#require` 會使測試失敗；
    ///   隔離目錄建立失敗時丟出 `.directoryCreationFailed`；store 檔搬移失敗時丟出 `.fileMoveFailed`
    @Test
    func quarantineStore_指定資料目錄_將Store檔移入隔離目錄() async throws {
        // Given
        let fixture = try ResidueProbeModels.makeDiskFixture()
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: fixture.directoryURL)
        }
        let database = BuyLedgerDatabaseTestSupport.makeDatabase(with: fixture)
        let fileManager = FileManager.default
        let storeURL = ResidueProbeModels.storeURL(in: fixture.directoryURL)
        try #require(fileManager.fileExists(atPath: storeURL.path))
        let service = withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            PersistenceRecoveryService.liveValue
        }

        // When
        try await service.quarantineStore()

        // Then
        let recoveredStoreURL = fixture.directoryURL
            .appendingPathComponent("Recovered-1", isDirectory: true)
            .appendingPathComponent("BuyLedger.store")
        #expect(!fileManager.fileExists(atPath: storeURL.path))
        #expect(fileManager.fileExists(atPath: recoveredStoreURL.path))
    }
}
