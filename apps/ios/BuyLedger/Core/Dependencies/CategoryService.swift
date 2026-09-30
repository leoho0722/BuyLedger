//
//  CategoryService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 商品類別主檔的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct CategoryService: Sendable {

    // MARK: - Properties

    /// 讀取目前所有類別名稱並排序
    ///
    /// - Returns: 已排序的類別名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchCategories: FetchCategories

    /// 加入新類別；去除前後空白後若為空字串則不處理
    ///
    /// - Parameter rawName: 尚未去除前後空白的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var addCategory: AddCategory

    /// 刪除指定名稱的類別；不存在時不做任何事
    ///
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removeCategory: RemoveCategory
}

// MARK: - Nested Types

extension CategoryService {

    /// `fetchCategories` 的函式型別
    typealias FetchCategories = @Sendable () async throws(PersistenceError) -> [String]

    /// `addCategory` 的函式型別
    typealias AddCategory = @Sendable (_ rawName: String) async throws(PersistenceError) -> Void

    /// `removeCategory` 的函式型別
    typealias RemoveCategory = @Sendable (_ name: String) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension CategoryService {

    /// 讀出全部類別名稱並依使用者語言排序
    ///
    /// - Parameter context: 本次交易使用的持久化 context
    /// - Returns: 已排序的類別名稱
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchCategories(in context: ModelContext) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<CategoryRecord>())
        }
        return records
            .map(\.name)
            .sorted { lhs, rhs in
                lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
    }

    /// 加入已正規化且尚不存在的類別名稱
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addCategory(rawName: String, in context: ModelContext) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.name == name })
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if existing == nil {
            context.insert(CategoryRecord(name: name))
        }
    }

    /// 刪除符合名稱的全部類別記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeCategory(name: String, in context: ModelContext) throws(PersistenceError) {
        let descriptor = FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.name == name })
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }
}
