//
//  BuyLedgerDatabase.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData

// MARK: - Protocol

/// 讓 Service 以一次性讀寫交易操作持久化資料，並在 store 損壞時隔離檔案
protocol BuyLedgerDatabaseProtocol: Sendable {

    /// 在資料庫 actor 中同步執行讀取主體
    ///
    /// - Parameter body: 以新建的 `ModelContext` 執行的讀取操作
    /// - Returns: 讀取操作的領域資料
    /// - Throws: 讀取主體定義的 `Failure`
    func read<Value: Sendable, Failure: Error>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value

    /// 在資料庫 actor 中同步執行寫入主體並保存變更
    ///
    /// - Parameter body: 以新建的 `ModelContext` 執行的寫入操作
    /// - Returns: 寫入操作的領域資料
    /// - Throws: 寫入主體定義的 `Failure`；儲存失敗時丟出 `Failure.storage(.saveFailed(underlying:))`
    func write<Value: Sendable, Failure: StorageFailureWrapping>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value

    /// 隔離目前的資料庫 store 並回傳備份目錄
    ///
    /// - Returns: 實際建立的備份目錄；記憶體資料庫或沒有可搬移的資料庫檔時回傳 `nil`
    /// - Throws: Application Support 路徑解析失敗時丟出 `.directoryResolutionFailed`；
    ///   備份目錄建立失敗時丟出 `.directoryCreationFailed`；store 檔搬移失敗時丟出 `.fileMoveFailed`
    func quarantineStore() async throws(PersistenceRecoveryError) -> URL?
}

// MARK: - Implementation

/// 以 actor 序列化交易，讓每次讀寫都使用獨立的持久化 context
actor BuyLedgerDatabase {

    // MARK: - Properties

    /// 建立交易 context 的 `ModelContainer`
    private let modelContainer: ModelContainer

    /// 隔離 store 時要處理的位置
    private let storeLocation: StoreLocation

    // MARK: - Init

    /// 建立使用指定容器並依指定位置隔離 store 的資料庫
    ///
    /// - Parameters:
    ///   - modelContainer: 要由交易建立 context 的 `ModelContainer`
    ///   - storeLocation: `quarantineStore()` 要處理的 `StoreLocation`
    init(modelContainer: ModelContainer, storeLocation: StoreLocation) {
        self.modelContainer = modelContainer
        self.storeLocation = storeLocation
    }
}

// MARK: - Nested Types

extension BuyLedgerDatabase {

    /// 指定 store 隔離的位置，並提供 Application Support 目錄的解析方式
    enum StoreLocation: Sendable {

        /// 使用注入的 closure 解析 Application Support 目錄
        ///
        /// - Parameter resolveDirectory: 回傳目錄；解析失敗時丟出底層錯誤
        case applicationSupport(resolveDirectory: @Sendable () throws -> URL)

        /// store 位於指定資料夾
        ///
        /// - Parameter url: store 所在的資料夾
        case directory(URL)

        /// store 只存在記憶體中
        case inMemory
    }
}

// MARK: - BuyLedgerDatabaseProtocol

extension BuyLedgerDatabase: BuyLedgerDatabaseProtocol {

    /// 在 actor 內建立新 context 執行讀取主體，結束後丟棄且不保存
    ///
    /// - Parameter body: 要在新建的 `ModelContext` 執行的讀取主體
    /// - Returns: `body` 的回傳值，原樣交回呼叫端
    /// - Throws: `body` 失敗時丟出其定義的 `Failure`
    func read<Value: Sendable, Failure: Error>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        let context = ModelContext(modelContainer)
        return try body(context)
    }

    /// 在 actor 內建立新 context，主體成功後只呼叫一次 `save()`
    ///
    /// - Parameter body: 要在新建的 `ModelContext` 執行的寫入主體
    /// - Returns: `body` 的回傳值，`save()` 成功後才交回
    /// - Throws: `body` 丟出其 `Failure`；`save()` 失敗丟出 `Failure.storage(.saveFailed(underlying:))`
    /// - Note: 主體或保存失敗後都直接丟棄 `context`，不執行 `rollback`
    func write<Value: Sendable, Failure: StorageFailureWrapping>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        let context = ModelContext(modelContainer)
        let value = try body(context)
        do {
            try context.save()
        } catch {
            throw Failure.storage(.saveFailed(underlying: error as NSError))
        }
        return value
    }

    /// 依 store 位置隔離資料庫，Application Support 目錄由 `StoreLocation` 的 closure 解析
    ///
    /// - Returns: 建立的備份目錄；`.inMemory` 或資料夾內沒有資料庫檔時為 `nil`
    /// - Throws: `resolveDirectory` 失敗時包成 `.directoryResolutionFailed`；其餘沿用
    ///   `PersistenceStoreQuarantine.quarantine` 丟出的 `.directoryCreationFailed` 或 `.fileMoveFailed`
    func quarantineStore() async throws(PersistenceRecoveryError) -> URL? {
        switch storeLocation {
        case .applicationSupport(let resolveDirectory):
            let applicationSupportDirectory: URL
            do {
                applicationSupportDirectory = try resolveDirectory()
            } catch {
                throw .directoryResolutionFailed(underlying: error as NSError)
            }
            return try PersistenceStoreQuarantine.quarantine(
                storeDirectory: applicationSupportDirectory,
                backupDirectory: applicationSupportDirectory
            )

        case .directory(let directory):
            return try PersistenceStoreQuarantine.quarantine(
                storeDirectory: directory,
                backupDirectory: directory
            )

        case .inMemory:
            return nil
        }
    }
}

// MARK: - DependencyKey

/// 把 `BuyLedgerDatabaseProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 seed 過的記憶體資料庫；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum BuyLedgerDatabaseKey: DependencyKey {

    /// 正式環境使用啟動時建立的 `ModelContainer`，並在依賴註冊處注入 Application Support 目錄解析
    static var liveValue: any BuyLedgerDatabaseProtocol {
        BuyLedgerDatabase(
            modelContainer: PersistenceContainer.bootstrap.container,
            storeLocation: .applicationSupport {
                try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        )
    }

    #if DEBUG

    /// Preview 使用已載入範例訂單與預設幣別的記憶體資料庫
    static var previewValue: any BuyLedgerDatabaseProtocol {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "BuyLedgerDatabaseKey.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        let modelContainer = PersistenceContainer.makeInMemory(for: .preview)
        let context = ModelContext(modelContainer)
        for order in LedgerOrder.sampleOrders {
            context.insert(OrderRecord(order: order))
        }
        // 幣別快取標成永不過期，Preview 的 `refreshIfStale` 不會發出網路請求
        for code in CurrencyCode.defaults {
            context.insert(CurrencyMetadataRecord(code: code.rawValue, lastUpdated: .distantFuture))
        }
        do {
            try context.save()
        } catch {
            // 記憶體資料庫 seed 失敗是程式錯誤
            fatalError("Preview database seed failed: \(error.localizedDescription)")
        }
        return BuyLedgerDatabase(modelContainer: modelContainer, storeLocation: .inMemory)
    }

    #endif
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 Service 的 `liveValue` 以 `@Dependency(\.buyLedgerDatabase)` 取得的資料庫
    var buyLedgerDatabase: any BuyLedgerDatabaseProtocol {
        get { self[BuyLedgerDatabaseKey.self] }
        set { self[BuyLedgerDatabaseKey.self] = newValue }
    }
}
