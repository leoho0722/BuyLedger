//
//  BuyLedgerDatabaseProtocol.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

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
