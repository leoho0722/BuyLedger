//
//  PersistenceContainer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import OSLog
import SwiftData

/// 建立 BuyLedger 的 `ModelContainer`，並記錄啟動時本機資料庫是否開得起來
enum PersistenceContainer {

    // MARK: - Properties

    /// App 執行期間只建立一次的啟動結果；正式環境的 `ModelContainer` 只由這裡取得
    static let bootstrap = makeBootstrap()
}

// MARK: - Nested Types

extension PersistenceContainer {

    /// App 持久層啟動結果
    struct Bootstrap: Sendable {

        /// 可供 SwiftData 使用的 `ModelContainer`；啟動狀態為 `degraded` 時是空的記憶體資料庫
        let container: ModelContainer

        /// 本機資料庫的開啟結果，決定能否呈現正常介面
        let status: Status
    }

    /// App 持久層啟動狀態
    enum Status: Equatable, Sendable {

        /// 本機資料庫正常開啟
        case healthy

        /// 本機資料庫無法開啟
        ///
        /// - Parameter reason: 資料庫無法開啟的原因，供 Crashlytics 記錄
        case degraded(reason: String)
    }

    /// 記憶體資料庫的使用情境
    enum InMemoryContext: Sendable {

        /// SwiftUI Preview
        case preview

        /// 單元測試與 UI 測試
        case testing

        /// 顯示在建立失敗訊息中的用途名稱
        var label: String {
            switch self {
            case .preview:
                "Preview"

            case .testing:
                "Test"
            }
        }
    }

    /// CloudKit 同步策略
    enum CloudKitOption: Equatable, Sendable {

        /// 關閉 CloudKit 同步 (純本機儲存)
        case disabled

        /// 由 SwiftData 自動從 entitlements 推斷 CloudKit container ID
        case automatic

        /// 同步到自訂 container 的 CloudKit 私有資料庫
        ///
        /// - Parameter identifier: CloudKit container 的 ID
        case privateContainer(String)

        /// 對應到 ``ModelConfiguration/CloudKitDatabase`` 的設定值
        var modelConfigurationValue: ModelConfiguration.CloudKitDatabase {
            switch self {
            case .disabled:
                return .none

            case .automatic:
                return .automatic

            case .privateContainer(let identifier):
                return .private(identifier)
            }
        }
    }
}

// MARK: - Internal Method

extension PersistenceContainer {

    /// 建立只存在記憶體中的 `ModelContainer`
    ///
    /// - Parameter context: 使用情境，建立失敗時用來標示訊息中的用途
    /// - Returns: 沒有任何資料的記憶體資料庫容器
    /// - Note: 建立失敗代表資料庫定義有誤，會直接中止 App
    static func makeInMemory(for context: InMemoryContext) -> ModelContainer {
        do {
            return try make(isInMemoryOnly: true, storeURL: nil)
        } catch {
            fatalError(
                "Unable to create the \(context.label) in-memory container: \(error.localizedDescription)"
            )
        }
    }

#if DEBUG
    /// 以指定路徑的資料庫檔建立啟動結果，讓測試檢查資料庫開得起來與開不起來時的結果；不影響正式的 `bootstrap`
    ///
    /// - Parameter storeURL: 測試用的資料庫檔案路徑
    /// - Returns: 資料庫打得開時狀態為 `.healthy`，打不開時改用記憶體資料庫且狀態為 `.degraded`
    static func makeBootstrapForTesting(storeURL: URL) -> Bootstrap {
        makeBootstrap(storeURL: storeURL)
    }

    /// 建立 UI 測試可跨 App 重啟使用的本機 `ModelContainer`
    ///
    /// - Parameter storeURL: UI 測試用的資料庫檔案路徑
    /// - Returns: 存在指定路徑的本機 `ModelContainer`
    /// - Throws: 資料庫所在資料夾或資料庫建立失敗時拋出 `.containerCreationFailed(underlying:)`
    static func makePersistentForTesting(storeURL: URL) throws(PersistenceError) -> ModelContainer {
        try make(isInMemoryOnly: false, storeURL: storeURL)
    }
#endif
}

// MARK: - Private Method

private extension PersistenceContainer {

    /// 建立 `Bootstrap`；磁碟上的資料庫打不開時，改用暫存在記憶體的空資料庫
    ///
    /// - Parameter storeURL: 指定資料庫位置；未提供時使用系統預設位置
    /// - Returns: 含 `ModelContainer` 的啟動結果，改用記憶體資料庫時狀態會帶著失敗原因
    static func makeBootstrap(storeURL: URL? = nil) -> Bootstrap {
        do {
            return Bootstrap(
                container: try make(isInMemoryOnly: false, storeURL: storeURL),
                status: .healthy
            )
        } catch {
            let reason = error.localizedDescription
            AppLogger.persistence.fault(
                "SwiftData store could not open: \(reason, privacy: .public)"
            )

            do {
                return Bootstrap(
                    container: try make(isInMemoryOnly: true, storeURL: nil),
                    status: .degraded(reason: reason)
                )
            } catch {
                let message = error.localizedDescription
                AppLogger.persistence.fault(
                    "SwiftData in-memory fallback could not open: \(message, privacy: .public)"
                )
                fatalError(
                    "SwiftData schema definition is invalid and cannot create an in-memory container."
                )
            }
        }
    }

    /// 建立 `ModelContainer`，可選擇存在磁碟或記憶體
    ///
    /// - Parameters:
    ///   - isInMemoryOnly: 是否只建立記憶體中的資料庫；有指定 `storeURL` 時以路徑為準
    ///   - storeURL: 資料庫路徑；`nil` 時，磁碟資料庫使用系統預設位置
    /// - Returns: 對應的 `ModelContainer`
    /// - Throws: 取得 Application Support、建立資料庫所在資料夾或建立 `ModelContainer` 失敗時拋出
    ///   `.containerCreationFailed(underlying:)`
    static func make(
        isInMemoryOnly: Bool,
        storeURL: URL?
    ) throws(PersistenceError) -> ModelContainer {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)

        let configuration: ModelConfiguration
        if let persistentStoreURL = try resolvePersistentStoreURL(
            requestedURL: storeURL,
            isInMemoryOnly: isInMemoryOnly
        ) {
            configuration = ModelConfiguration(
                "BuyLedger",
                schema: schema,
                url: persistentStoreURL,
                allowsSave: true,
                cloudKitDatabase: CloudKitOption.disabled.modelConfigurationValue
            )
        } else {
            configuration = ModelConfiguration(
                "BuyLedger",
                schema: schema,
                isStoredInMemoryOnly: isInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: CloudKitOption.disabled.modelConfigurationValue
            )
        }

        let container = try PersistenceError.mapContainerCreation {
            try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: configuration
            )
        }

        return container
    }

    /// 決定磁碟資料庫的檔案路徑並建立其所在資料夾
    ///
    /// - Parameters:
    ///   - requestedURL: 呼叫端指定的資料庫路徑；`nil` 時使用 Application Support 資料夾
    ///   - isInMemoryOnly: 是否只建立記憶體中的資料庫
    /// - Returns: 磁碟資料庫的檔案路徑；不需要磁碟資料庫時為 `nil`
    /// - Throws: 取得 Application Support 或建立資料庫所在資料夾失敗時拋出
    ///   `.containerCreationFailed(underlying:)`
    static func resolvePersistentStoreURL(
        requestedURL: URL?,
        isInMemoryOnly: Bool
    ) throws(PersistenceError) -> URL? {
        guard !isInMemoryOnly || requestedURL != nil else {
            return nil
        }

        let storeURL: URL
        if let requestedURL {
            storeURL = requestedURL
        } else {
            do {
                let applicationSupport = try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                storeURL = applicationSupport.appendingPathComponent("BuyLedger.store")
            } catch {
                throw .containerCreationFailed(underlying: error as NSError)
            }
        }

        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw .containerCreationFailed(underlying: error as NSError)
        }

        return storeURL
    }
}
