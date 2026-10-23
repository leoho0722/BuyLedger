//
//  PersistenceRecoveryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture

/// 將無法開啟的資料庫 store 移到隔離備份目錄；
/// 正式實作在 `liveValue`、Preview 在 `previewValue`、測試預設值在 `testValue`
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

// MARK: - DependencyKey

extension PersistenceRecoveryService: DependencyKey {

    /// 正式 App 委由 Database 隔離 store，位置依 Database 建立時指定的 `storeLocation`；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            quarantineStore: { [database] () throws(PersistenceRecoveryError) in
                _ = try await database.quarantineStore()
            }
        )
    }

    #if DEBUG

    /// Preview 使用各 Service 共用、只存在記憶體的資料庫，不會搬移檔案；誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PersistenceRecoveryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }

    #endif

    /// 測試預設不搬移 store，未覆寫時會回報未實作 issue
    static var testValue: Self {
        Self(
            quarantineStore: unimplemented("PersistenceRecoveryService.quarantineStore")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供持久層失敗畫面取得 store 隔離操作
    var persistenceRecoveryService: PersistenceRecoveryService {
        get { self[PersistenceRecoveryService.self] }
        set { self[PersistenceRecoveryService.self] = newValue }
    }
}
