//
//  BLUITestHarness.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Dependencies
import Foundation
import SwiftData

#if DEBUG

/// UI 測試模式的啟動 harness
///
/// - Note: 必須早於第一次解析 `@Dependency`
@MainActor
enum BLUITestHarness {

    // MARK: - Properties

    /// UI 測試模式使用的 container；正式執行為 `nil`
    private(set) static var modelContainer: ModelContainer?
}

// MARK: - Internal Method

@MainActor
extension BLUITestHarness {

    /// 帶 UI 測試啟動參數時完成全部前置注入，否則直接返回不影響正式路徑
    static func prepareIfNeeded() {
        let configuration = BLUITestConfiguration.current

        guard configuration.isEnabled else {
            return
        }

        let container: ModelContainer
        let storeLocation: BuyLedgerDatabase.StoreLocation

        switch configuration.persistenceMode {
        case .inMemory:
            resetPersistedState()
            container = PersistenceContainer.makeInMemory(for: .testing)
            storeLocation = .inMemory
            BLUITestSeedData.seed(
                configuration.seedProfile,
                into: container,
                referenceDate: configuration.referenceDate
            )

        case .persistent:
            let storeURL = preparePersistentStoreURL(for: configuration)
            storeLocation = .directory(storeURL.deletingLastPathComponent())
            let hasExistingStore = FileManager.default.fileExists(atPath: storeURL.path)

            if configuration.resetPersistentStore {
                resetPersistedState()
                removePersistentStore(at: storeURL)
            }

            do {
                container = try PersistenceContainer.makePersistentForTesting(storeURL: storeURL)
            } catch {
                // UI 測試環境建不起來就無法進行測試，直接中止讓失敗立即浮現
                fatalError(
                    "Unable to create the persistent UI test container: \(error.localizedDescription)"
                )
            }

            if configuration.resetPersistentStore || !hasExistingStore {
                BLUITestSeedData.seed(
                    configuration.seedProfile,
                    into: container,
                    referenceDate: configuration.referenceDate
                )
            }
        }

        modelContainer = container

        prepareDependencies {
            $0.applyUITestOverrides(
                configuration,
                container: container,
                storeLocation: storeLocation
            )
        }
    }
}

// MARK: - Private Method

@MainActor
private extension BLUITestHarness {

    /// 清除 App 的 `UserDefaults` 測試資料
    static func resetPersistedState() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        } else {
            print("[BuyLedger][UITest] 取不到 bundle identifier，跳過設定重置")
        }
    }

    /// 取得 UI 測試使用的穩定 store 路徑，必要時建立資料夾
    ///
    /// - Parameter configuration: UI 測試啟動設定
    /// - Returns: 依種子 profile 分隔的 persistent store 路徑
    static func preparePersistentStoreURL(for configuration: BLUITestConfiguration) -> URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directory = applicationSupport.appendingPathComponent(
            "BuyLedgerUITest",
            isDirectory: true
        )

        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            // UI 測試環境建不起來就無法進行測試，直接中止讓失敗立即浮現
            fatalError(
                "Unable to create the persistent UI test directory: \(error.localizedDescription)"
            )
        }

        return directory.appendingPathComponent("\(configuration.seedProfile.rawValue).store")
    }

    /// 清除指定 persistent store 及 SQLite sidecar 檔案
    ///
    /// - Parameter storeURL: 要清除的 store 路徑
    static func removePersistentStore(at storeURL: URL) {
        let candidates = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal"),
        ]

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            do {
                try FileManager.default.removeItem(at: candidate)
            } catch {
                // UI 測試環境建不起來就無法進行測試，直接中止讓失敗立即浮現
                fatalError(
                    "Unable to reset the persistent UI test store: \(error.localizedDescription)"
                )
            }
        }
    }
}

#endif
