//
//  PersistenceStoreQuarantine.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/26.
//

import Foundation

/// 將無法開啟的資料庫檔案搬到使用者可保留的隔離備份目錄
/// - Note: 搬移中途失敗可能只完成部分檔案。
enum PersistenceStoreQuarantine {}

// MARK: - Internal Method

extension PersistenceStoreQuarantine {

    /// 將指定資料夾中的資料庫與附屬檔案搬到下一個可用的隔離備份目錄
    /// - Parameters:
    ///   - storeDirectory: 存放資料庫的來源資料夾
    ///   - backupDirectory: 用於建立 `Recovered-N` 子目錄的目標資料夾
    /// - Returns: 實際建立的隔離備份目錄；沒有可搬移的資料庫檔時為 `nil`
    /// - Throws: 目錄建立或檔案搬移失敗時拋出 ``PersistenceRecoveryError``
    static func quarantine(
        storeDirectory: URL,
        backupDirectory: URL
    ) throws(PersistenceRecoveryError) -> URL? {
        let fileManager = FileManager.default
        let storeFiles = storeFileURLs(in: storeDirectory, fileManager: fileManager)

        guard !storeFiles.isEmpty else {
            return nil
        }

        do {
            try fileManager.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw .directoryCreationFailed(underlying: error as NSError)
        }
        let recoveredDirectory = nextAvailableDirectory(
            in: backupDirectory,
            fileManager: fileManager
        )
        do {
            try fileManager.createDirectory(
                at: recoveredDirectory,
                withIntermediateDirectories: false
            )
        } catch {
            throw .directoryCreationFailed(underlying: error as NSError)
        }

        for storeFile in storeFiles {
            do {
                try fileManager.moveItem(
                    at: storeFile,
                    to: recoveredDirectory.appendingPathComponent(storeFile.lastPathComponent)
                )
            } catch {
                throw .fileMoveFailed(
                    fileName: storeFile.lastPathComponent,
                    underlying: error as NSError
                )
            }
        }

        return recoveredDirectory
    }
}

// MARK: - Private Method

private extension PersistenceStoreQuarantine {

    /// 資料庫與附屬檔案的檔名清單
    static let storeFileNames = [
        "BuyLedger.store",
        "BuyLedger.store-wal",
        "BuyLedger.store-shm",
        "default.store",
        "default.store-wal",
        "default.store-shm",
    ]

    /// 取得指定資料夾中存在的資料庫與附屬檔案路徑
    /// - Parameters:
    ///   - directory: 資料庫所在資料夾
    ///   - fileManager: 使用的檔案管理器
    /// - Returns: 存在的資料庫與附屬檔案路徑清單
    static func storeFileURLs(
        in directory: URL,
        fileManager: FileManager
    ) -> [URL] {
        storeFileNames
            .map { directory.appendingPathComponent($0) }
            .filter { fileManager.fileExists(atPath: $0.path) }
    }

    /// 依序找出下一個可用的 `Recovered-N` 目錄
    /// - Parameters:
    ///   - backupDirectory: 用於建立 `Recovered-N` 子目錄的目標目錄
    ///   - fileManager: 使用的檔案管理器
    /// - Returns: 尚未存在的 `Recovered-N` 目錄路徑
    static func nextAvailableDirectory(
        in backupDirectory: URL,
        fileManager: FileManager
    ) -> URL {
        var index = 1

        while true {
            let candidate = backupDirectory.appendingPathComponent(
                "Recovered-\(index)",
                isDirectory: true
            )
            guard !fileManager.fileExists(atPath: candidate.path) else {
                index += 1
                continue
            }
            return candidate
        }
    }
}
