//
//  PersistenceContainer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import OSLog
import SwiftData

/// 建立 BuyLedger 用的 ``ModelContainer`` 的工廠
enum PersistenceContainer {
    
    // MARK: - Static Properties
    
    /// 整個 process 只解析一次的啟動結果
    nonisolated static let bootstrap = makeBootstrap()
    
    /// 所有 production repository 共用的 container
    nonisolated static var shared: ModelContainer { bootstrap.container }
}

// MARK: - Nested Types

extension PersistenceContainer {
    
    /// App 持久層啟動結果
    struct Bootstrap: Sendable {
        
        /// 可供 SwiftData 使用的 container
        let container: ModelContainer
        
        /// 是否可安全呈現正常介面
        let outcome: Outcome
    }
    
    /// App 持久層啟動狀態
    enum Outcome: Equatable, Sendable {
        
        /// on-disk store 正常開啟
        case healthy
        
        /// on-disk store 無法開啟
        /// - Parameter reason: store 無法開啟的原因，供 Crashlytics 記錄
        case degraded(reason: String)
    }
    
    /// 記憶體資料庫的使用情境
    enum InMemoryContext: Sendable {
        
        /// SwiftUI Preview
        case preview
        
        /// 測試
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
        
        /// CloudKit 私有資料庫的 container ID
        case privateContainer(String)
        
        /// 對應到 ``ModelConfiguration/CloudKitDatabase`` 的設定值
        nonisolated var modelConfigurationValue: ModelConfiguration.CloudKitDatabase {
            switch self {
            case .disabled:
                return .none
            case .automatic:
                return .automatic
            case let .privateContainer(identifier):
                return .private(identifier)
            }
        }
    }
}

// MARK: - Internal Method

extension PersistenceContainer {
    
    /// 建立只存在記憶體中的 ModelContainer
    /// - Parameter context: 使用情境
    nonisolated static func makeInMemory(for context: InMemoryContext) -> ModelContainer {
        do {
            return try make(inMemoryOnly: true, storeURL: nil)
        } catch {
            fatalError(
                "Unable to create the \(context.label) in-memory container: "
                + error.localizedDescription
            )
        }
    }
    
#if DEBUG
    /// 測試低於 migration floor 的實體 store 時使用，不會影響 production bootstrap
    /// - Parameter storeURL: 測試用的舊版 store 路徑
    nonisolated static func makeBootstrapForTesting(storeURL: URL) -> Bootstrap {
        makeBootstrap(storeURL: storeURL)
    }

    /// 建立 UI 測試可跨 App 重啟使用的本機 container
    /// - Parameter storeURL: UI 測試用的 persistent store 路徑
    /// - Returns: 指定路徑的本機 ModelContainer
    /// - Throws: store 無法建立時拋出 PersistenceError
    nonisolated static func makePersistentForTesting(storeURL: URL) throws(PersistenceError) -> ModelContainer {
        try make(inMemoryOnly: false, storeURL: storeURL)
    }
#endif
}

// MARK: - Private Method

private extension PersistenceContainer {
    
    /// 建立 ``Bootstrap``，若 on-disk store 無法開啟則降級為 in-memory fallback
    /// - Parameter storeURL: 指定資料庫位置；未提供時使用系統預設位置
    /// - Returns: ``Bootstrap``，包含 container 與啟動狀態
    static func makeBootstrap(storeURL: URL? = nil) -> Bootstrap {
        do {
            return Bootstrap(
                container: try make(inMemoryOnly: false, storeURL: storeURL),
                outcome: .healthy
            )
        } catch {
            let reason = error.localizedDescription
            Logger(subsystem: "com.leoho.BuyLedger", category: "Persistence")
                .fault(
                    "SwiftData store could not open: \(reason, privacy: .public)"
                )
            
            do {
                return Bootstrap(
                    container: try make(inMemoryOnly: true, storeURL: nil),
                    outcome: .degraded(reason: reason)
                )
            } catch {
                let message = error.localizedDescription
                Logger(subsystem: "com.leoho.BuyLedger", category: "Persistence")
                    .fault(
                        "SwiftData in-memory fallback could not open: \(message, privacy: .public)"
                    )
                fatalError(
                    "SwiftData schema definition is invalid and cannot create " + "an in-memory container."
                )
            }
        }
    }
    
    /// 建立 ModelContainer，可選擇磁碟或記憶體儲存
    /// - Parameters:
    ///   - inMemoryOnly: 是否建立僅存於記憶體的 store
    ///   - storeURL: 資料庫路徑；nil 使用系統預設位置
    /// - Returns: 對應的 ``ModelContainer`` 實例
    /// - Throws: ModelContainer 建立失敗時拋出 ``PersistenceError``
    static func make(
        inMemoryOnly: Bool,
        storeURL: URL?
    ) throws(PersistenceError) -> ModelContainer {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        
        let configuration: ModelConfiguration
        if let persistentStoreURL = try resolvePersistentStoreURL(
            requestedURL: storeURL,
            inMemoryOnly: inMemoryOnly
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
                isStoredInMemoryOnly: inMemoryOnly,
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

    /// 解析磁碟型 store 路徑並建立其父目錄
    /// - Parameters:
    ///   - requestedURL: 呼叫端指定的 store 路徑；`nil` 時使用 Application Support
    ///   - inMemoryOnly: 是否只建立記憶體型 store
    /// - Returns: 磁碟型 store 路徑；記憶體型 store 回傳 `nil`
    /// - Throws: Application Support 或 store 父目錄建立失敗時拋出 ``PersistenceError``
    static func resolvePersistentStoreURL(
        requestedURL: URL?,
        inMemoryOnly: Bool
    ) throws(PersistenceError) -> URL? {
        guard !inMemoryOnly || requestedURL != nil else {
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
                throw .containerCreationFailed(message: error.localizedDescription)
            }
        }

        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw .containerCreationFailed(message: error.localizedDescription)
        }

        return storeURL
    }
}
