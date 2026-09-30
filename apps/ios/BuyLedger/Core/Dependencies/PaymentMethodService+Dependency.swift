//
//  PaymentMethodService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension PaymentMethodService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行 `PaymentMethodService` 操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchPaymentMethodInfos: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchPaymentMethodInfos(in: context)
                }
            },
            addPaymentMethod: { rawName, flags throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addPaymentMethod(rawName: rawName, flags: flags, in: context)
                }
            },
            removePaymentMethod: { name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removePaymentMethod(name: name, in: context)
                }
            },
            applyPaymentMethodEdit: { oldName, newName, flags, orders throws(PaymentMethodPersistenceError) in
                try await database.write { context throws(PaymentMethodPersistenceError) in
                    try Self.applyPaymentMethodEdit(
                        from: oldName,
                        to: newName,
                        flags: flags,
                        orders: orders,
                        in: context
                    )
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchPaymentMethodInfos: unimplemented(
                "PaymentMethodService.fetchPaymentMethodInfos",
                placeholder: []
            ),
            addPaymentMethod: unimplemented("PaymentMethodService.addPaymentMethod"),
            removePaymentMethod: unimplemented("PaymentMethodService.removePaymentMethod"),
            applyPaymentMethodEdit: unimplemented("PaymentMethodService.applyPaymentMethodEdit")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.paymentMethodService)` 取得的 Payment Method Service
    var paymentMethodService: PaymentMethodService {
        get { self[PaymentMethodService.self] }
        set { self[PaymentMethodService.self] = newValue }
    }
}
