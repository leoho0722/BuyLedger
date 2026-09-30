//
//  PaymentMethodPersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 付款方式持久化的錯誤
enum PaymentMethodPersistenceError: Error, Sendable {

    /// 批次更新時找不到指定訂單
    ///
    /// - Parameter id: 找不到的訂單編號
    case orderNotFound(id: LedgerOrder.ID)

    /// 持久化基礎操作失敗
    ///
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

// MARK: - StorageFailureWrapping

extension PaymentMethodPersistenceError: StorageFailureWrapping {}
