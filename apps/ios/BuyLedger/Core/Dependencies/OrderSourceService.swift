//
//  OrderSourceService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 訂單來源主檔的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct OrderSourceService: Sendable {

    // MARK: - Properties

    /// 讀取目前所有訂單來源名稱並排序
    ///
    /// - Returns: 已排序的訂單來源名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchOrderSources: FetchOrderSources

    /// 加入新訂單來源；去除前後空白後若為空字串則不處理
    ///
    /// - Parameter rawName: 尚未去除前後空白的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var addOrderSource: AddOrderSource

    /// 刪除指定名稱的訂單來源；不存在時不做任何事
    ///
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeOrderSource: RemoveOrderSource
}

// MARK: - Nested Types

extension OrderSourceService {

    /// `fetchOrderSources` 的函式型別
    typealias FetchOrderSources = @Sendable () async throws(PersistenceError) -> [String]

    /// `addOrderSource` 的函式型別
    typealias AddOrderSource = @Sendable (_ rawName: String) async throws(PersistenceError) -> Void

    /// `removeOrderSource` 的函式型別
    typealias RemoveOrderSource = @Sendable (_ name: String) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension OrderSourceService {

    /// 讀出全部訂單來源名稱並依使用者語言排序
    ///
    /// - Parameter context: 本次讀取使用的持久化 context
    /// - Returns: 已排序的訂單來源名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchOrderSources(in context: ModelContext) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderSourceRecord>())
        }
        return records
            .map(\.name)
            .sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
    }

    /// 加入已正規化且尚不存在的訂單來源名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addOrderSource(rawName: String, in context: ModelContext) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<OrderSourceRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if existing == nil {
            context.insert(OrderSourceRecord(name: name))
        }
    }

    /// 刪除符合名稱的全部訂單來源記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeOrderSource(name: String, in context: ModelContext) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderSourceRecord>(
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
