//
//  ReconciliationStatusService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension ReconciliationStatusService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行 `ReconciliationStatusService` 操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchReconciliationStatuses: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchReconciliationStatuses(in: context)
                }
            },
            addReconciliationStatus: { rawName throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addReconciliationStatus(rawName: rawName, in: context)
                }
            },
            removeReconciliationStatus: { name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeReconciliationStatus(name: name, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchReconciliationStatuses: unimplemented(
                "ReconciliationStatusService.fetchReconciliationStatuses",
                placeholder: []
            ),
            addReconciliationStatus: unimplemented(
                "ReconciliationStatusService.addReconciliationStatus"
            ),
            removeReconciliationStatus: unimplemented(
                "ReconciliationStatusService.removeReconciliationStatus"
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.reconciliationStatusService)` 取得的 Reconciliation Status Service
    var reconciliationStatusService: ReconciliationStatusService {
        get { self[ReconciliationStatusService.self] }
        set { self[ReconciliationStatusService.self] = newValue }
    }
}
