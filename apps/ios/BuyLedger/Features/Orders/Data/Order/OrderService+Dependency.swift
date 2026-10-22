//
//  OrderService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension OrderService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行訂單操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchOrders: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchOrders(in: context)
                }
            },
            createOrder: { order throws(OrderError) in
                try await database.write { context throws(OrderError) in
                    try Self.createOrder(order, in: context)
                }
            },
            saveOrder: { order throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrder(order, in: context)
                }
            },
            saveOrders: { orders throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrders(orders, in: context)
                }
            },
            fetchOrderPhotos: { id throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchOrderPhotos(id: id, in: context)
                }
            },
            saveOrderPersistingPhotos: { order throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrderPersistingPhotos(order, in: context)
                }
            },
            removeOrder: { id throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeOrder(id: id, in: context)
                }
            },
            mergeOrders: { newOrder, consumedIDs throws(OrderError) in
                try await database.write { context throws(OrderError) in
                    try Self.mergeOrders(newOrder, consumedIDs: consumedIDs, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchOrders: unimplemented("OrderService.fetchOrders", placeholder: []),
            createOrder: unimplemented("OrderService.createOrder"),
            saveOrder: unimplemented("OrderService.saveOrder"),
            saveOrders: unimplemented("OrderService.saveOrders"),
            fetchOrderPhotos: unimplemented("OrderService.fetchOrderPhotos", placeholder: []),
            saveOrderPersistingPhotos: unimplemented("OrderService.saveOrderPersistingPhotos"),
            removeOrder: unimplemented("OrderService.removeOrder"),
            mergeOrders: unimplemented("OrderService.mergeOrders")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.orderService)` 取得的 Order Service
    var orderService: OrderService {
        get {
            self[OrderService.self]
        }
        set {
            self[OrderService.self] = newValue
        }
    }
}
