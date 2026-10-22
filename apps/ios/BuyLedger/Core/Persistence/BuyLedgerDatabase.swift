//
//  BuyLedgerDatabase.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

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
    /// - Returns: 讀取操作的領域資料
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
    /// - Returns: 寫入操作的領域資料
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
    /// - Throws: `resolveDirectory` 失敗時丟出 `.directoryResolutionFailed`；
    ///   隔離目錄建立失敗時丟出 `.directoryCreationFailed`；store 檔搬移失敗時丟出 `.fileMoveFailed`
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
