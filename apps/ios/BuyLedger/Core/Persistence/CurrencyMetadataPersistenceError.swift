//
//  CurrencyMetadataPersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 幣別快取持久化的錯誤
enum CurrencyMetadataPersistenceError: Error, Sendable {

    /// API 沒有回傳任何支援幣別
    case emptyCodeList

    /// 持久化基礎操作失敗
    ///
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

// MARK: - StorageFailureWrapping

extension CurrencyMetadataPersistenceError: StorageFailureWrapping {}
