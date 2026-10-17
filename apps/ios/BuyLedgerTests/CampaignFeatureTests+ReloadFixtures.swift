//
//  CampaignFeatureTests+ReloadFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import SwiftData

@testable import BuyLedger

// MARK: - Nested Types

extension CampaignFeatureTests {

    /// 指定重新載入前要觸發的失敗寫入操作
    enum ReloadConsistencyWrite: Sendable {

        /// 新增開團
        case create

        /// 寫入既有開團
        case save

        /// 移除既有開團
        case remove
    }
}

// MARK: - Internal Method

extension CampaignFeatureTests {

    /// 建立含初始開團的 V17 唯讀資料庫
    ///
    /// - Parameter initialCampaigns: 要寫入資料庫的開團清單
    /// - Returns: 只能讀取的資料庫與專屬暫存目錄
    /// - Throws: 建立暫存目錄或 SwiftData 容器失敗時拋出系統錯誤；寫入初始開團失敗時拋出 `PersistenceError`
    static func makeReloadConsistencyDatabase(
        seeding initialCampaigns: [Campaign]
    ) async throws(any Error) -> (database: BuyLedgerDatabase, directoryURL: URL) {
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(
                path: "BuyLedgerCampaignReloadTest-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        var isDirectoryTransferred = false
        defer {
            if !isDirectoryTransferred {
                BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
            }
        }
        let storeURL = directoryURL.appending(
            path: "CampaignReload.store",
            directoryHint: .notDirectory
        )
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let writableConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let writableContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: writableConfiguration
            )
        }
        let writableDatabase = BuyLedgerDatabase(
            modelContainer: writableContainer,
            storeLocation: .directory(directoryURL)
        )
        let campaignService = CampaignServiceTests.makeService(database: writableDatabase)
        for campaign in initialCampaigns {
            try await campaignService.saveCampaign(campaign)
        }

        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let readOnlyContainer = try TestContainerCreationLock.withLock {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: readOnlyConfiguration
            )
        }
        let database = BuyLedgerDatabase(
            modelContainer: readOnlyContainer,
            storeLocation: .directory(directoryURL)
        )
        isDirectoryTransferred = true
        return (database, directoryURL)
    }

    /// 建立只注入重新載入與指定失敗寫入的 `CampaignFeature` `TestStore`
    ///
    /// - Parameters:
    ///   - initialState: 測試開始時的 feature 狀態
    ///   - database: 重新載入與失敗寫入使用的唯讀資料庫
    ///   - write: 要注入的寫入操作
    /// - Returns: 使用唯讀資料庫依賴的 `TestStore`
    static func makeReloadConsistencyStore(
        initialState: CampaignFeature.State,
        database: any BuyLedgerDatabaseProtocol,
        write: ReloadConsistencyWrite
    ) -> TestStoreOf<CampaignFeature> {
        let campaignService = CampaignServiceTests.makeService(database: database)

        return TestStore(initialState: initialState) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = campaignService.fetchCampaigns
            switch write {
            case .create:
                $0.uuid = .incrementing
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .save:
                $0.campaignService.saveCampaign = campaignService.saveCampaign

            case .remove:
                $0.campaignService.removeCampaign = campaignService.removeCampaign
            }
        }
    }
}
