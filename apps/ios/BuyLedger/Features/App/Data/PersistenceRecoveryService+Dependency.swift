//
//  PersistenceRecoveryService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture

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
