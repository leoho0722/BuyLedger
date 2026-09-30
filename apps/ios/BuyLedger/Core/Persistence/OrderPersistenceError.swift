//
//  OrderPersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 訂單持久化的錯誤
enum OrderPersistenceError: Error, Sendable {

    /// 建立或合併時發現相同訂單編號
    ///
    /// - Parameter id: 發生衝突的訂單編號
    case identifierCollision(id: String)

    /// 持久化基礎操作失敗
    ///
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

// MARK: - StorageFailureWrapping

extension OrderPersistenceError: StorageFailureWrapping {}
