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

/// 驗證 store 隔離復原與容器建立錯誤分類
struct PersistenceRecoveryTests {

    // MARK: - Properties

    /// 測試專用的暫存根目錄
    private static let testRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("BuyLedgerPersistenceRecoveryTests", isDirectory: true)

    // MARK: - Tests

    /// 隔離指定資料目錄時移動 store 與 sidecar 檔案並保留位元內容
    ///
    /// - Throws: 測試目錄建立或檔案寫入、讀取失敗時拋出底層檔案錯誤；隔離失敗時拋出 `PersistenceRecoveryError`；
    ///   沒有回傳隔離目錄時由 `#require` 拋出
    @Test
    func quarantine_指定資料目錄_移動資料庫檔案並保留內容() throws(any Error) {
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
            let sourceURL = sourceDirectory.appendingPathComponent(name)
            #expect(!FileManager.default.fileExists(atPath: sourceURL.path))
            let recoveredContents = try Data(contentsOf: recovered.appendingPathComponent(name))
            #expect(recoveredContents == contents)
        }
    }

    /// 隔離目錄的第一個序號已存在時改用下一個序號
    ///
    /// - Throws: 測試目錄建立或檔案寫入失敗時拋出底層檔案錯誤；隔離失敗時拋出 `PersistenceRecoveryError`
    @Test
    func quarantine_目標序號已存在_使用下一個復原序號() throws(any Error) {
        // Given
        let sourceDirectory = try Self.prepareDirectory(named: "increments-index")
        let backupDirectory = try Self.prepareDirectory(named: "increments-index-backups")
        try FileManager.default.createDirectory(
            at: backupDirectory.appendingPathComponent("Recovered-1", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Self.writeStoreFiles(in: sourceDirectory)

        // When
        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )

        // Then
        #expect(recoveredDirectory?.lastPathComponent == "Recovered-2")
    }

    /// 來源沒有 store 檔案時回傳 nil 且不建立隔離目錄
    ///
    /// - Throws: 測試來源目錄建立失敗時拋出底層檔案錯誤；隔離失敗時拋出 `PersistenceRecoveryError`
    @Test
    func quarantine_沒有資料庫檔案_回傳空值且不建立目錄() throws(any Error) {
        // Given
        let sourceDirectory = try Self.prepareDirectory(named: "nothing-to-quarantine")
        let backupDirectory = sourceDirectory.appendingPathComponent("backups", isDirectory: true)

        // When
        let recoveredDirectory = try PersistenceStoreQuarantine.quarantine(
            storeDirectory: sourceDirectory,
            backupDirectory: backupDirectory
        )

        // Then
        #expect(recoveredDirectory == nil)
        #expect(!FileManager.default.fileExists(atPath: backupDirectory.path))
    }

    /// 隔離目錄路徑已是檔案時回報目錄建立錯誤與底層 Cocoa 錯誤碼
    ///
    /// - Throws: 測試檔案建立失敗，或未取得預期錯誤時由 `#require` 拋出錯誤
    @Test
    func quarantine_建立備份目錄失敗_回報復原錯誤() throws(any Error) {
        // Given
        let sourceDirectory = try Self.prepareDirectory(named: "backup-path-is-file")
        let backupPath = sourceDirectory.appendingPathComponent("backup-target", isDirectory: true)
        try Data([0x01]).write(to: backupPath)
        try Self.writeStoreFiles(in: sourceDirectory)
        var actualError: PersistenceRecoveryError?

        // When
        do {
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: sourceDirectory,
                backupDirectory: backupPath
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        switch error {
        case .directoryCreationFailed(let underlying):
            let cocoaError = underlying as NSError
            #expect(cocoaError.domain == NSCocoaErrorDomain)
            #expect(cocoaError.code == NSFileWriteFileExistsError)

        case .directoryResolutionFailed, .fileMoveFailed:
            Issue.record("預期會得到 directoryCreationFailed 復原錯誤。")
        }
    }

    /// `PersistenceRecoveryError` 的顯示文字沿用底層錯誤描述
    @Test
    func errorDescription_復原錯誤包含底層原因_回傳底層本地化說明() {
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
        #expect(actualDescription == "Recovery directory is unavailable.")
    }

    /// `BuyLedger.store-wal` 被鎖定無法搬移時，搬檔失敗應指出該 sidecar 檔名與底層權限錯誤
    ///
    /// - Throws: 測試檔案建立或鎖定設定失敗時拋出錯誤；未取得預期錯誤時由 `#require` 拋出
    @Test
    func quarantine_移動資料庫檔案失敗_回報檔名與底層錯誤() throws(any Error) {
        // Given
        let sourceDirectory = try Self.prepareDirectory(named: "sidecar-file-is-locked")
        let backupDirectory = try Self.prepareDirectory(named: "sidecar-file-is-locked-backups")
        try Self.writeStoreFiles(in: sourceDirectory)
        let sidecarURL = sourceDirectory.appendingPathComponent("BuyLedger.store-wal")
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: sidecarURL.path)
        defer {
            try? FileManager.default.setAttributes( // 失敗可忽略，因為鎖定只影響本測試暫存目錄
                [.immutable: false],
                ofItemAtPath: sidecarURL.path
            )
        }
        var actualError: PersistenceRecoveryError?

        // When
        do {
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: sourceDirectory,
                backupDirectory: backupDirectory
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        switch error {
        case .fileMoveFailed(let fileName, let underlying):
            #expect(fileName == "BuyLedger.store-wal")
            let cocoaError = underlying as NSError
            #expect(cocoaError.domain == NSCocoaErrorDomain)
            #expect(cocoaError.code == NSFileWriteNoPermissionError)

        case .directoryResolutionFailed, .directoryCreationFailed:
            Issue.record("錯誤應為 fileMoveFailed 復原錯誤")
        }
    }

    /// 舊版 schema 無法遷移時以 `degraded` 狀態啟動並完整保留來源 store
    ///
    /// - Throws: 測試目錄建立、舊版資料庫建立或檔案讀取失敗時拋出錯誤；建立後檔案組合不符時由 `#require` 拋出
    @Test
    func makeBootstrapForTesting_資料庫無法遷移_原地保留資料庫() throws(any Error) {
        // Given
        let sourceDirectory = try Self.prepareDirectory(named: "below-migration-floor")
        let storeURL = sourceDirectory.appendingPathComponent("BuyLedger.store")
        let sourceContainer = try Self.createBelowFloorStore(at: storeURL)

        let originalFiles = try Self.storeFiles(in: sourceDirectory)
        let expectedNames: Set<String> = [
            "BuyLedger.store", "BuyLedger.store-wal", "BuyLedger.store-shm",
        ]
        try #require(Set(originalFiles.keys) == expectedNames)

        // When
        let bootstrap = TestContainerCreationLock.withLock {
            PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        }

        // Then
        #expect(bootstrap.status != .healthy)
        let preservedFiles = try Self.storeFiles(in: sourceDirectory)
        #expect(preservedFiles == originalFiles)
        let sourceContents = try FileManager.default.contentsOfDirectory(
            atPath: sourceDirectory.path
        )
        #expect(!sourceContents.contains { $0.hasPrefix("Recovered-") })

        // 保留容器以避免 SQLite 釋放時 checkpoint 並刪除 -wal／-shm，造成檔案比對失真
        withExtendedLifetime(sourceContainer) {}
    }

    /// 資料庫容器整個 process 只建立一次，之後每次取用 `bootstrap` 都拿到同一個 `ModelContainer`
    @Test
    func bootstrap_連續存取_回傳同一容器() {
        // Given

        // When
        let (first, second) = TestContainerCreationLock.withLock {
            (PersistenceContainer.bootstrap.container, PersistenceContainer.bootstrap.container)
        }

        // Then
        #expect(first === second)
    }

    /// 資料庫父目錄不存在時建立目錄並回傳持久化容器
    ///
    /// - Throws: 資料庫資料夾或容器建立失敗時拋出 `PersistenceError.containerCreationFailed(underlying:)`
    @Test
    func makePersistentForTesting_資料庫目錄不存在_建立目錄並回傳容器() throws(any Error) {
        // Given
        let root = Self.testRoot.appendingPathComponent(
            "creates-missing-store-directory-\(UUID().uuidString)",
            isDirectory: true
        )
        let storeURL = root
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent("BuyLedger.store")
        defer {
            try? FileManager.default.removeItem(at: root) // 失敗可忽略，因為目錄名稱含 UUID，不影響其他測試
        }

        // When
        let container = try TestContainerCreationLock.withLock { () throws(PersistenceError) in
            try PersistenceContainer.makePersistentForTesting(storeURL: storeURL)
        }

        // Then
        #expect(FileManager.default.fileExists(atPath: storeURL.deletingLastPathComponent().path))
        withExtendedLifetime(container) {}
    }

    /// 建立持久化容器時無法建立父目錄應分類為容器建立失敗
    ///
    /// - Throws: 測試檔案建立失敗，或未取得預期錯誤時由 `#require` 拋出錯誤
    @Test
    func makePersistentForTesting_父路徑是檔案_回報容器建立錯誤() throws(any Error) {
        // Given
        let root = try Self.prepareDirectory(named: "container-parent-is-file")
        let blockedParent = root.appendingPathComponent("blocked-parent")
        try Data([0x01]).write(to: blockedParent)
        let storeURL = blockedParent.appendingPathComponent("BuyLedger.store")
        defer {
            try? FileManager.default.removeItem(at: root) // 失敗可忽略，因為目錄名稱含序號，不影響其他測試
        }
        var actualError: PersistenceError?

        // When
        do {
            _ = try TestContainerCreationLock.withLock { () throws(PersistenceError) in
                try PersistenceContainer.makePersistentForTesting(storeURL: storeURL)
            }
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError)
        switch error {
        case .containerCreationFailed(let underlying):
            let cocoaError = underlying as NSError
            #expect(cocoaError.domain == NSCocoaErrorDomain)
            #expect(cocoaError.code == NSFileWriteFileExistsError)

        case .fetchFailed, .saveFailed:
            Issue.record("預期為 containerCreationFailed PersistenceError。")
        }
    }
}

// MARK: - Nested Types

extension PersistenceRecoveryTests {

    /// 版本低於 migration floor 的舊版 schema
    ///
    /// - Note: `@Model` 巨集展開在檔案層級，巢狀型別不能是 `private`
    enum BelowMigrationFloorSchema: VersionedSchema {

        /// 舊版 store 唯一的資料表，用來寫入一筆舊資料
        @Model
        final class LegacyRecord {

            /// 遷移前保存的文字
            var value: String

            /// 建立舊版持久化資料模型
            ///
            /// - Parameter value: 遷移前保存的文字
            init(value: String) {
                self.value = value
            }
        }

        /// 固定為 14，低於 `BuyLedgerMigrationPlan.schemas` 最舊的 V15，讓啟動時找不到遷移路徑
        static var versionIdentifier: Schema.Version {
            Schema.Version(14, 0, 0)
        }

        /// 此 schema 唯一包含的持久化模型
        static var models: [any PersistentModel.Type] {
            [LegacyRecord.self]
        }
    }
}

// MARK: - Private Method

private extension PersistenceRecoveryTests {

    /// 建立測試專用的暫存目錄，並依序編號避免重複
    ///
    /// - Parameter name: 暫存目錄名稱
    /// - Returns: 建立的暫存目錄
    /// - Throws: 暫存目錄建立失敗時拋出錯誤
    static func prepareDirectory(named name: String) throws(any Error) -> URL {
        var index = 1

        while true {
            let directory = testRoot.appendingPathComponent("\(name)-\(index)", isDirectory: true)

            if FileManager.default.fileExists(atPath: directory.path) {
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
    ///
    /// - Parameter directory: store 所在的目錄
    /// - Returns: 寫入的檔案內容
    /// - Throws: 測試檔案寫入失敗時拋出錯誤
    @discardableResult
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

    /// 建立低於 migration floor 的舊版 store，供驗證 bootstrap 的降級保留行為
    ///
    /// - Parameter url: store 路徑
    /// - Returns: 建立的 `ModelContainer`
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    static func createBelowFloorStore(at url: URL) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: Self.BelowMigrationFloorSchema.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try TestContainerCreationLock.withLock {
            try ModelContainer(for: schema, configurations: configuration)
        }
        let context = ModelContext(container)
        context.insert(Self.BelowMigrationFloorSchema.LegacyRecord(value: "legacy"))
        try context.save()
        return container
    }

    /// 取得指定目錄中存在的 store 與 sidecar 檔案內容
    ///
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
}
