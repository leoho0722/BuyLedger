//
//  LookupService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

extension LookupService: DependencyKey {

    /// 正式 App 使用的主檔操作，資料庫由依賴系統取得
    static var liveValue: Self {
        // 以 computed property 每次重新解析依賴，測試才能用 `withDependencies` 替換資料庫
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchItems: { kind throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchItems(kind, in: context)
                }
            },
            addItem: { kind, addition throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addItem(kind, addition: addition, in: context)
                }
            },
            removeItem: { kind, name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeItem(kind, name: name, in: context)
                }
            },
            renameItem: { kind, rename throws(PersistenceError) in
                guard let newName = Self.normalizedRenameTarget(
                    oldName: rename.oldName,
                    newName: rename.newName
                ) else {
                    return
                }
                try await database.write { context throws(PersistenceError) in
                    try Self.renameItem(
                        kind,
                        from: rename.oldName,
                        to: newName,
                        in: context
                    )
                }
            },
            countOrders: { paymentMethod throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.countOrders(paymentMethod: paymentMethod, in: context)
                }
            },
            applyPaymentMethodEdit: { originalName, newName, flags throws(PersistenceError) in
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return []
                }
                return try await database.write { context throws(PersistenceError) in
                    try Self.applyPaymentMethodEdit(
                        from: originalName,
                        to: trimmedName,
                        flags: flags,
                        in: context
                    )
                }
            }
        )
    }

    /// 每個操作都必須由測試明確覆寫，未覆寫的呼叫會回報失敗
    static var testValue: Self {
        Self(
            fetchItems: unimplemented("LookupService.fetchItems", placeholder: LookupCatalog()),
            addItem: unimplemented("LookupService.addItem"),
            removeItem: unimplemented("LookupService.removeItem"),
            renameItem: unimplemented("LookupService.renameItem"),
            countOrders: unimplemented("LookupService.countOrders", placeholder: 0),
            applyPaymentMethodEdit: unimplemented(
                "LookupService.applyPaymentMethodEdit",
                placeholder: []
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 Feature 以 `@Dependency(\.lookupService)` 取得的主檔 Service
    var lookupService: LookupService {
        get {
            self[LookupService.self]
        }
        set {
            self[LookupService.self] = newValue
        }
    }
}
