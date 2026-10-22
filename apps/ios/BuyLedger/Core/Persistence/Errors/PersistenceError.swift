//
//  PersistenceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/4.
//

import Foundation
import SwiftData

/// 讀取、寫入或建立本機資料庫失敗時的錯誤，保留底層錯誤供診斷
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

// MARK: - Internal Method

extension PersistenceError {

    /// 把讀取操作丟出的錯誤轉成 `NSError`，包成持久化錯誤
    ///
    /// - Parameter operation: 可能拋出底層錯誤的讀取操作
    /// - Returns: 讀取操作的結果
    /// - Throws: `operation` 失敗時以 `.fetchFailed(underlying:)` 包裝原始錯誤
    static func mapFetch<Value>(
        _ operation: () throws(any Error) -> Value
    ) throws(PersistenceError) -> Value {
        do {
            return try operation()
        } catch {
            throw .fetchFailed(underlying: error as NSError)
        }
    }

    /// 把寫入操作丟出的錯誤轉成 `NSError`，包成持久化錯誤
    ///
    /// - Parameter operation: 可能拋出底層錯誤的寫入操作
    /// - Throws: `operation` 失敗時以 `.saveFailed(underlying:)` 包裝原始錯誤
    static func mapSave(_ operation: () throws(any Error) -> Void) throws(PersistenceError) {
        do {
            try operation()
        } catch {
            throw .saveFailed(underlying: error as NSError)
        }
    }

    /// 把容器建立操作丟出的錯誤轉成 `NSError`，包成持久化錯誤
    ///
    /// - Parameter operation: 可能拋出底層錯誤的容器建立操作
    /// - Returns: 建立完成的持久化容器
    /// - Throws: `operation` 失敗時以 `.containerCreationFailed(underlying:)` 包裝原始錯誤
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

// MARK: - StorageFailureWrapping

extension PersistenceError: StorageFailureWrapping {

    /// 保留寫入操作原本的持久化錯誤
    ///
    /// - Parameter error: 寫入操作的持久化失敗
    /// - Returns: 傳入的持久化錯誤
    static func storage(_ error: PersistenceError) -> Self {
        error
    }
}
