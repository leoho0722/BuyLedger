//
//  OrderSourceService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension OrderSourceService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行 `OrderSourceService` 操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchOrderSources: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchOrderSources(in: context)
                }
            },
            addOrderSource: { rawName throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addOrderSource(rawName: rawName, in: context)
                }
            },
            removeOrderSource: { name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeOrderSource(name: name, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchOrderSources: unimplemented(
                "OrderSourceService.fetchOrderSources",
                placeholder: []
            ),
            addOrderSource: unimplemented("OrderSourceService.addOrderSource"),
            removeOrderSource: unimplemented("OrderSourceService.removeOrderSource")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.orderSourceService)` 取得的 Order Source Service
    var orderSourceService: OrderSourceService {
        get { self[OrderSourceService.self] }
        set { self[OrderSourceService.self] = newValue }
    }
}
