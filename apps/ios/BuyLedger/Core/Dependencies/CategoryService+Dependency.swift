//
//  CategoryService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

// MARK: - DependencyKey

extension CategoryService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行類別主檔操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchCategories: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchCategories(in: context)
                }
            },
            addCategory: { rawName throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addCategory(rawName: rawName, in: context)
                }
            },
            removeCategory: { name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeCategory(name: name, in: context)
                }
            }
        )
    }

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchCategories: unimplemented("CategoryService.fetchCategories", placeholder: []),
            addCategory: unimplemented("CategoryService.addCategory"),
            removeCategory: unimplemented("CategoryService.removeCategory")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.categoryService)` 取得的 Category Service
    var categoryService: CategoryService {
        get { self[CategoryService.self] }
        set { self[CategoryService.self] = newValue }
    }
}
