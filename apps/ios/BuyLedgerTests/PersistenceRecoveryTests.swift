//
//  PersistenceRecoveryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/26.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證持久層復原
@MainActor
struct PersistenceRecoveryTests {
    
    // MARK: - Quarantine
    
    @Test func quarantineMovesStoreFilesWithoutChangingTheirContents() throws(any Error) {
        let sourceDirectory = try Self.prepareDirectory(named: "move-preserves-contents")
        let backupDirectory = try Self.prepareDirectory(named: "move-preserves-contents-backups")
        let expectedFiles = try Self.writeStoreFiles(in: sourceDirectory)
        
        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )
        
        let recovered = try #require(recoveredDirectory)
        for (name, contents) in expectedFiles {
            #expect(
                !FileManager.default.fileExists(
                    atPath: sourceDirectory.appendingPathComponent(name).path))
            let recoveredContents = try Data(contentsOf: recovered.appendingPathComponent(name))
            #expect(recoveredContents == contents)
        }
    }
    
    @Test func quarantineUsesNextAvailableRecoveryIndex() throws(any Error) {
        let sourceDirectory = try Self.prepareDirectory(named: "increments-index")
        let backupDirectory = try Self.prepareDirectory(named: "increments-index-backups")
        try FileManager.default.createDirectory(
            at: backupDirectory.appendingPathComponent("Recovered-1", isDirectory: true),
            withIntermediateDirectories: true
        )
        _ = try Self.writeStoreFiles(in: sourceDirectory)
        
        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )
        
        #expect(recoveredDirectory?.lastPathComponent == "Recovered-2")
    }
    
    @Test func quarantineWithoutAStoreReturnsNilAndDoesNotCreateDirectory() throws(any Error) {
        let sourceDirectory = try Self.prepareDirectory(named: "nothing-to-quarantine")
        let backupDirectory = Self.testRoot.appendingPathComponent(
            "nothing-to-quarantine-backups",
            isDirectory: true
        )
        
        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )
        
        #expect(recoveredDirectory == nil)
        #expect(!FileManager.default.fileExists(atPath: backupDirectory.path))
    }
    
    @Test func quarantineMapsBackupDirectoryFailureToARecoveryError() throws(any Error) {
        let sourceDirectory = try Self.prepareDirectory(named: "backup-path-is-file")
        let backupPath = sourceDirectory.appendingPathComponent("backup-target", isDirectory: true)
        try Data([0x01]).write(to: backupPath)
        _ = try Self.writeStoreFiles(in: sourceDirectory)
        
        do {
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: sourceDirectory,
                backupDirectory: backupPath
            )
            Issue.record("Expected quarantine to reject a backup path occupied by a file.")
        } catch let error {
            guard case let .directoryCreationFailed(message) = error else {
                Issue.record("Expected a directoryCreationFailed recovery error.")
                return
            }
            #expect(!message.isEmpty)
        }
    }
    
    // MARK: - Bootstrap Preservation
    
    @Test func bootstrapPreservesAnUnmigratableStoreInPlace() throws(any Error) {
        let sourceDirectory = try Self.prepareDirectory(named: "below-migration-floor")
        let storeURL = sourceDirectory.appendingPathComponent("BuyLedger.store")
        let sourceContainer = try Self.createBelowFloorStore(at: storeURL)
        
        let originalFiles = try Self.storeFiles(in: sourceDirectory)
        #expect(
            Set(originalFiles.keys) == [
                "BuyLedger.store", "BuyLedger.store-wal", "BuyLedger.store-shm",
            ])
        let bootstrap = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        
        guard case .degraded = bootstrap.outcome else {
            Issue.record("Expected an unmigratable store to produce a degraded bootstrap outcome.")
            return
        }
        let preservedFiles = try Self.storeFiles(in: sourceDirectory)
        #expect(preservedFiles == originalFiles)
        let sourceContents = try FileManager.default.contentsOfDirectory(
            atPath: sourceDirectory.path)
        #expect(
            !sourceContents.contains(where: { $0.hasPrefix("Recovered-") })
        )
        
        withExtendedLifetime(sourceContainer) {}
    }
    
    @Test func sharedContainerIsResolvedOnlyOnce() {
        #expect(PersistenceContainer.shared === PersistenceContainer.shared)
    }
}

/// 建立低於 migration floor 的舊版 schema
private enum BelowMigrationFloorSchema: VersionedSchema {
    
    // MARK: - Static Properties
    
    static var versionIdentifier: Schema.Version { Schema.Version(14, 0, 0) }
    
    static var models: [any PersistentModel.Type] {
        [LegacyRecord.self]
    }
    
    // MARK: - Nested Types
    /// 舊版持久化資料模型
    @Model
    final class LegacyRecord {
        
        var value: String
        
        init(value: String) {
            self.value = value
        }
    }
}

// MARK: - Private Method

private extension PersistenceRecoveryTests {
    
    /// 測試專用的暫存根目錄
    static let testRoot: URL = {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerPersistenceRecoveryTests", isDirectory: true)
    }()
    
    /// 建立測試專用的暫存目錄，並依序編號避免重複
    /// - Parameter name: 暫存目錄名稱
    /// - Returns: 建立的暫存目錄
    /// - Throws: 暫存目錄建立失敗時拋出錯誤
    static func prepareDirectory(named name: String) throws(any Error) -> URL {
        var index = 1
        
        while true {
            let directory = testRoot.appendingPathComponent("\(name)-\(index)", isDirectory: true)
            
            guard !FileManager.default.fileExists(atPath: directory.path) else {
                index += 1
                continue
            }
            
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory
        }
    }
    
    /// 將測試用的 store 檔案寫入指定目錄
    /// - Parameter directory: store 所在的目錄
    /// - Returns: 寫入的檔案內容
    /// - Throws: 測試檔案寫入失敗時拋出錯誤
    static func writeStoreFiles(in directory: URL) throws(any Error) -> [String: Data] {
        let files = [
            "BuyLedger.store": Data([0x01, 0x02, 0x03]),
            "BuyLedger.store-wal": Data([0x04, 0x05]),
            "BuyLedger.store-shm": Data([0x06]),
            "default.store": Data([0x07, 0x08]),
        ]
        
        for (name, contents) in files {
            try contents.write(to: directory.appendingPathComponent(name))
        }
        
        return files
    }
    
    /// 取得指定目錄中存在的 store 與 sidecar 檔案內容
    /// - Parameter directory: store 所在的目錄
    /// - Returns: store 檔案內容
    /// - Throws: 測試檔案讀取失敗時拋出錯誤
    static func storeFiles(in directory: URL) throws(any Error) -> [String: Data] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("BuyLedger.store") }
            .reduce(into: [:]) { files, name in
                files[name] = try Data(contentsOf: directory.appendingPathComponent(name))
            }
    }
    
    /// 建立低於 migration floor 的舊版 store，供驗證 bootstrap 的降級保留行為
    /// - Parameter url: store 路徑
    /// - Returns: 建立的 ModelContainer
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    static func createBelowFloorStore(at url: URL) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: BelowMigrationFloorSchema.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        context.insert(BelowMigrationFloorSchema.LegacyRecord(value: "legacy"))
        try context.save()
        return container
    }
}
