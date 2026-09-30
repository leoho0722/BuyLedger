//
//  ReconciliationStatusService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 對帳狀態主檔的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct ReconciliationStatusService: Sendable {

    // MARK: - Properties

    /// 讀取目前所有對帳狀態名稱並排序
    ///
    /// - Returns: 已排序的對帳狀態名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchReconciliationStatuses: FetchReconciliationStatuses

    /// 加入新對帳狀態；去除前後空白後若為空字串則不處理
    ///
    /// - Parameter rawName: 尚未去除前後空白的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var addReconciliationStatus: AddReconciliationStatus

    /// 刪除指定名稱的對帳狀態；不存在時不做任何事
    ///
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeReconciliationStatus: RemoveReconciliationStatus
}

// MARK: - Nested Types

extension ReconciliationStatusService {

    /// `fetchReconciliationStatuses` 的函式型別
    typealias FetchReconciliationStatuses = @Sendable () async throws(PersistenceError) -> [String]

    /// `addReconciliationStatus` 的函式型別
    typealias AddReconciliationStatus = @Sendable (
        _ rawName: String
    ) async throws(PersistenceError) -> Void

    /// `removeReconciliationStatus` 的函式型別
    typealias RemoveReconciliationStatus = @Sendable (
        _ name: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension ReconciliationStatusService {

    /// 讀出全部對帳狀態名稱並依使用者語言排序
    ///
    /// - Parameter context: 本次交易使用的持久化 context
    /// - Returns: 已排序的對帳狀態名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchReconciliationStatuses(
        in context: ModelContext
    ) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<ReconciliationStatusRecord>())
        }
        return records
            .map(\.name)
            .sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
    }

    /// 加入已正規化且尚不存在的對帳狀態名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addReconciliationStatus(
        rawName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<ReconciliationStatusRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if existing == nil {
            context.insert(ReconciliationStatusRecord(name: name))
        }
    }

    /// 刪除符合名稱的全部對帳狀態記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeReconciliationStatus(
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<ReconciliationStatusRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }
}
