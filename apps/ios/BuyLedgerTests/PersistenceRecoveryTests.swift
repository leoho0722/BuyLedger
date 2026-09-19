//
//  PersistenceRecoveryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/07/26.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

/// 驗證持久層復原
@MainActor
struct PersistenceRecoveryTests {

    // MARK: - Quarantine

    /// 驗證持久化復原在此情境下的結果
    @Test func quarantineMovesStoreFilesWithoutChangingTheirContents() throws(any Error) {
        // Given

        let sourceDirectory = try Self.prepareDirectory(named: "move-preserves-contents")
        let backupDirectory = try Self.prepareDirectory(named: "move-preserves-contents-backups")
        let expectedFiles = try Self.writeStoreFiles(in: sourceDirectory)

        // When

        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )

        // Then

        let recovered = try #require(recoveredDirectory)
        for (name, contents) in expectedFiles {
            #expect(
                !FileManager.default.fileExists(
                    atPath: sourceDirectory.appendingPathComponent(name).path))
            let recoveredContents = try Data(contentsOf: recovered.appendingPathComponent(name))
            #expect(recoveredContents == contents)
        }
    }

    /// 驗證持久化復原在此情境下的結果
    @Test func quarantineUsesNextAvailableRecoveryIndex() throws(any Error) {
        // Given

        let sourceDirectory = try Self.prepareDirectory(named: "increments-index")
        let backupDirectory = try Self.prepareDirectory(named: "increments-index-backups")
        try FileManager.default.createDirectory(
            at: backupDirectory.appendingPathComponent("Recovered-1", isDirectory: true),
            withIntermediateDirectories: true
        )
        _ = try Self.writeStoreFiles(in: sourceDirectory)

        // When

        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )

        // Then

        #expect(recoveredDirectory?.lastPathComponent == "Recovered-2")
    }

    /// 驗證持久化復原在此情境下的結果
    @Test func quarantineWithoutAStoreReturnsNilAndDoesNotCreateDirectory() throws(any Error) {
        // Given

        let sourceDirectory = try Self.prepareDirectory(named: "nothing-to-quarantine")
        let backupDirectory = Self.testRoot.appendingPathComponent(
            "nothing-to-quarantine-backups",
            isDirectory: true
        )

        // When

        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )

        // Then

        #expect(recoveredDirectory == nil)
        #expect(!FileManager.default.fileExists(atPath: backupDirectory.path))
    }

    /// 驗證持久化復原在此情境下的結果
    @Test func quarantineMapsBackupDirectoryFailureToARecoveryError() throws(any Error) {
        // Given

        let sourceDirectory = try Self.prepareDirectory(named: "backup-path-is-file")
        let backupPath = sourceDirectory.appendingPathComponent("backup-target", isDirectory: true)
        try Data([0x01]).write(to: backupPath)
        _ = try Self.writeStoreFiles(in: sourceDirectory)

        // When

        do {
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: sourceDirectory,
                backupDirectory: backupPath
            )

            // Then

            Issue.record("預期隔離流程會拒絕被檔案佔用的備份路徑。")
        } catch let error {
            // Then

            guard case let .directoryCreationFailed(underlying) = error else {
                Issue.record("預期會得到 directoryCreationFailed 復原錯誤。")
                return
            }
            #expect(!underlying.localizedDescription.isEmpty)
        }
    }

    /// recovery error 的顯示文字應沿用來源錯誤描述
    @Test
    func recoveryErrorDescriptionUsesUnderlyingLocalizedDescription() {
        // Given

        let sourceError = NSError(
            domain: "com.leoho.BuyLedger.recovery-test",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Recovery directory is unavailable."]
        )
        let error = PersistenceRecoveryError.directoryCreationFailed(underlying: sourceError)

        // When

        let actualDescription = error.errorDescription

        // Then

        #expect(actualDescription == sourceError.localizedDescription)
    }

    /// 來源目錄不可寫時，搬檔失敗應指出第一個無法搬移的檔案
    ///
    /// - Throws: 測試檔案建立或權限設定失敗時拋出錯誤
    @Test
    func quarantineFileMoveFailureReportsFileName() throws(any Error) {
        // Given：來源目錄含 store 檔案但不允許寫入
        let sourceDirectory = try Self.prepareDirectory(named: "source-path-is-read-only")
        let backupDirectory = try Self.prepareDirectory(named: "source-path-is-read-only-backups")
        _ = try Self.writeStoreFiles(in: sourceDirectory)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: sourceDirectory.path
        )
        defer {
            // 還原權限失敗不影響測試結果，暫存目錄稍後即刪除
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: sourceDirectory.path
            )
        }

        // When
        do {
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: sourceDirectory,
                backupDirectory: backupDirectory
            )
            Issue.record("隔離搬移應回報檔案搬移失敗")
        } catch {
            // Then
            if case .fileMoveFailed(let fileName, let underlying) = error {
                #expect(fileName == "BuyLedger.store")
                #expect(!underlying.localizedDescription.isEmpty)
            } else {
                Issue.record("錯誤應為 fileMoveFailed 復原錯誤")
            }
        }
    }

    // MARK: - Bootstrap Preservation

    /// 驗證持久化復原在此情境下的結果
    @Test func bootstrapPreservesAnUnmigratableStoreInPlace() throws(any Error) {
        // Given

        let sourceDirectory = try Self.prepareDirectory(named: "below-migration-floor")
        let storeURL = sourceDirectory.appendingPathComponent("BuyLedger.store")
        let sourceContainer = try Self.createBelowFloorStore(at: storeURL)

        let originalFiles = try Self.storeFiles(in: sourceDirectory)
        #expect(
            Set(originalFiles.keys) == [
                "BuyLedger.store", "BuyLedger.store-wal", "BuyLedger.store-shm",
            ])

        // When

        let bootstrap = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)

        // Then

        guard case .degraded = bootstrap.status else {
            Issue.record("預期無法遷移的資料庫會產生 degraded 啟動狀態。")
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

    /// 驗證持久化復原在此情境下的結果
    @Test func sharedContainerIsResolvedOnlyOnce() {
        // Given

        // When

        let first = PersistenceContainer.shared
        let second = PersistenceContainer.shared

        // Then

        #expect(first === second)
    }

    /// 驗證持久化復原在此情境下的結果
    @Test func persistentContainerCreatesMissingStoreDirectory() throws(any Error) {
        // Given

        let root = Self.testRoot.appendingPathComponent(
            "creates-missing-store-directory-\(UUID().uuidString)",
            isDirectory: true
        )
        let storeURL = root
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent("BuyLedger.store")
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        // When

        let container = try PersistenceContainer.makePersistentForTesting(storeURL: storeURL)

        // Then

        #expect(FileManager.default.fileExists(atPath: storeURL.deletingLastPathComponent().path))
        withExtendedLifetime(container) {}
    }

    /// 建立持久化容器時無法建立父目錄應分類為容器建立失敗
    @Test func persistentContainerMapsDirectoryFailureToContainerCreationError()
        throws(any Error) {
        // Given

        let root = try Self.prepareDirectory(named: "container-parent-is-file")
        let blockedParent = root.appendingPathComponent("blocked-parent")
        try Data([0x01]).write(to: blockedParent)
        let storeURL = blockedParent.appendingPathComponent("BuyLedger.store")
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        // When

        do {
            _ = try PersistenceContainer.makePersistentForTesting(storeURL: storeURL)
            // Then

            Issue.record("預期父目錄無法建立時會拋出 containerCreationFailed。")
        } catch {
            switch error {
            case let .containerCreationFailed(underlying):
                #expect(!underlying.localizedDescription.isEmpty)
            case .fetchFailed, .saveFailed:
                Issue.record("預期為 containerCreationFailed PersistenceError。")
            }
        }
    }
}

/// 建立低於 migration floor 的舊版 schema
private enum BelowMigrationFloorSchema: VersionedSchema {

    // MARK: - Computed Properties

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
