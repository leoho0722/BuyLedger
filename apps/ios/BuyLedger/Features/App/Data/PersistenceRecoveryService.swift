//
//  PersistenceRecoveryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

/// 將無法開啟的資料庫 store 移到隔離備份目錄；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct PersistenceRecoveryService: Sendable {

    // MARK: - Properties

    /// 將目前 store 檔與附屬檔 (`-wal`、`-shm`) 移到隔離備份目錄
    ///
    /// - Throws: Application Support 路徑解析失敗時丟出 `.directoryResolutionFailed`；
    ///   備份目錄建立失敗時丟出 `.directoryCreationFailed`；store 檔搬移失敗時丟出 `.fileMoveFailed`
    var quarantineStore: QuarantineStore
}

// MARK: - Nested Types

extension PersistenceRecoveryService {

    /// `quarantineStore` 的函式型別
    typealias QuarantineStore = @Sendable () async throws(PersistenceRecoveryError) -> Void
}
