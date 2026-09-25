//
//  PersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/4.
//

import Foundation
import SwiftData

/// 持久化基礎層的錯誤
enum PersistenceError: Error, Sendable {

    /// 讀取資料失敗
    ///
    /// - Parameter underlying: 讀取操作原本拋出的錯誤
    case fetchFailed(underlying: any Error & Sendable)

    /// 寫入資料失敗
    ///
    /// - Parameter underlying: 寫入操作原本拋出的錯誤
    case saveFailed(underlying: any Error & Sendable)

    /// 建立持久化容器失敗
    ///
    /// - Parameter underlying: 建立操作原本拋出的錯誤
    case containerCreationFailed(underlying: any Error & Sendable)
}

/// 訂單持久化的錯誤
enum OrderPersistenceError: Error, Sendable {

    /// 建立或合併時發現相同訂單編號
    /// - Parameter id: 發生衝突的訂單編號
    case identifierCollision(id: String)

    /// 持久化基礎操作失敗
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

/// 付款方式持久化的錯誤
enum PaymentMethodPersistenceError: Error, Sendable {

    /// 批次更新時找不到指定訂單
    /// - Parameter id: 找不到的訂單編號
    case orderNotFound(id: LedgerOrder.ID)

    /// 持久化基礎操作失敗
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

/// 幣別快取持久化的錯誤
enum CurrencyMetadataPersistenceError: Error, Sendable {

    /// API 沒有回傳任何支援幣別
    case emptyCodeList

    /// 持久化基礎操作失敗
    /// - Parameter persistenceError: 持久化基礎層拋出的錯誤
    case storage(PersistenceError)
}

/// 復原搬移資料庫檔案時發生的錯誤
enum PersistenceRecoveryError: Error, Sendable {

    /// 解析 Application Support 目錄失敗
    ///
    /// - Parameter underlying: 解析目錄時原本拋出的錯誤
    case directoryResolutionFailed(underlying: any Error & Sendable)

    /// 建立復原目錄失敗
    ///
    /// - Parameter underlying: 建立目錄時原本拋出的錯誤
    case directoryCreationFailed(underlying: any Error & Sendable)

    /// 搬移資料庫檔案失敗
    ///
    /// - Parameters:
    ///   - fileName: 無法搬移的檔案名稱
    ///   - underlying: 搬移檔案時原本拋出的錯誤
    case fileMoveFailed(fileName: String, underlying: any Error & Sendable)
}

// MARK: - LocalizedError

extension PersistenceRecoveryError: LocalizedError {

    /// 顯示底層錯誤訊息
    /// - Returns: 要顯示給使用者的錯誤訊息
    var errorDescription: String? {
        switch self {
        case let .directoryResolutionFailed(underlying), let .directoryCreationFailed(underlying):
            underlying.localizedDescription
        case let .fileMoveFailed(fileName, underlying):
            "\(fileName): \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Internal Method

extension PersistenceError {

    /// 將讀取操作的原始錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的讀取操作
    /// - Returns: 讀取操作的結果
    /// - Throws: 讀取操作失敗時拋出 ``PersistenceError``
    static func mapFetch<Value>(
        _ operation: () throws(any Error) -> Value
    ) throws(PersistenceError) -> Value {
        do {
            return try operation()
        } catch {
            throw .fetchFailed(underlying: error as NSError)
        }
    }

    /// 將寫入操作的原始錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的寫入操作
    /// - Throws: 寫入操作失敗時拋出 ``PersistenceError``
    static func mapSave(_ operation: () throws(any Error) -> Void) throws(PersistenceError) {
        do {
            try operation()
        } catch {
            throw .saveFailed(underlying: error as NSError)
        }
    }

    /// 將建立持久化容器的原始錯誤轉成持久化錯誤
    /// - Parameter operation: 可能拋出原始錯誤的容器建立操作
    /// - Returns: 建立完成的持久化容器
    /// - Throws: 容器建立失敗時拋出 ``PersistenceError``
    static func mapContainerCreation(
        _ operation: () throws(any Error) -> ModelContainer
    ) throws(PersistenceError) -> ModelContainer {
        do {
            return try operation()
        } catch {
            throw .containerCreationFailed(underlying: error as NSError)
        }
    }
}
