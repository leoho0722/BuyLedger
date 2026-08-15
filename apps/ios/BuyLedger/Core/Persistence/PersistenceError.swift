//
//  PersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/4.
//

import Foundation

/// 持久化基礎層的錯誤
enum PersistenceError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// 讀取資料失敗
    case fetchFailed(message: String)
    
    /// 寫入資料失敗
    case saveFailed(message: String)
    
    /// 建立 ModelContainer 失敗
    case containerCreationFailed(message: String)
    
    // MARK: - Computed Properties
    
    /// 顯示底層錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .fetchFailed(message), let .saveFailed(message),
            let .containerCreationFailed(message):
            message
        }
    }
}

/// 訂單持久化的錯誤
enum OrderPersistenceError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// 建立或合併時發現相同訂單編號
    case identifierCollision(id: String)
    
    /// 持久化基礎操作失敗
    case storage(PersistenceError)
    
    // MARK: - Computed Properties
    
    /// 顯示錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .identifierCollision(id):
            "訂單編號已存在：\(id)"
        case let .storage(error):
            error.localizedDescription
        }
    }
}

/// 付款方式持久化的錯誤
enum PaymentMethodPersistenceError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// 批次更新時找不到指定訂單
    case orderNotFound(id: LedgerOrder.ID)
    
    /// 持久化基礎操作失敗
    case storage(PersistenceError)
    
    // MARK: - Computed Properties
    
    /// 顯示錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .orderNotFound(id):
            "找不到訂單：\(id)"
        case let .storage(error):
            error.localizedDescription
        }
    }
}

/// 幣別快取持久化的錯誤
enum CurrencyMetadataPersistenceError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// API 沒有回傳任何支援幣別
    case emptyCodeList
    
    /// 持久化基礎操作失敗
    case storage(PersistenceError)
    
    // MARK: - Computed Properties
    
    /// 顯示錯誤訊息
    var errorDescription: String? {
        switch self {
        case .emptyCodeList:
            "支援幣別清單為空。"
        case let .storage(error):
            error.localizedDescription
        }
    }
}

/// store 復原搬移的錯誤
enum PersistenceRecoveryError: Error, Equatable, LocalizedError, Sendable {
    
    // MARK: - Cases
    
    /// 解析 Application Support 目錄失敗
    case directoryResolutionFailed(message: String)
    
    /// 建立復原目錄失敗
    case directoryCreationFailed(message: String)
    
    /// 搬移 store 檔案失敗
    case fileMoveFailed(fileName: String, message: String)
    
    // MARK: - Computed Properties
    
    /// 顯示底層錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .directoryResolutionFailed(message), let .directoryCreationFailed(message):
            message
        case let .fileMoveFailed(fileName, message):
            "\(fileName): \(message)"
        }
    }
}

// MARK: - Internal Method

extension PersistenceError {
    
    /// 將 fetch 的原始錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的 fetch 操作
    /// - Returns: fetch 操作的結果
    /// - Throws: operation 失敗時拋出 ``PersistenceError``
    static func mapFetch<T>(_ operation: () throws(any Error) -> T) throws(PersistenceError) -> T {
        do {
            return try operation()
        } catch {
            throw .fetchFailed(message: error.localizedDescription)
        }
    }
    
    /// 將 save 的原始錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的 save 操作
    /// - Throws: operation 失敗時拋出 ``PersistenceError``
    static func mapSave(_ operation: () throws(any Error) -> Void) throws(PersistenceError) {
        do {
            try operation()
        } catch {
            throw .saveFailed(message: error.localizedDescription)
        }
    }
    
    /// 將 ModelContainer 建立錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的 container 建立操作
    /// - Returns: 建立完成的 ModelContainer
    /// - Throws: operation 失敗時拋出 ``PersistenceError``
    static func mapContainerCreation<T>(
        _ operation: () throws(any Error) -> T
    ) throws(PersistenceError) -> T {
        do {
            return try operation()
        } catch {
            throw .containerCreationFailed(message: error.localizedDescription)
        }
    }
}
