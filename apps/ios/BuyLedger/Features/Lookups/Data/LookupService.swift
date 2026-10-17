//
//  LookupService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData

/// 四種主檔與引用訂單的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 在 `previewValue`
struct LookupService: Sendable {

    // MARK: - Properties

    /// 讀取指定種類的主檔，其他種類保持空白
    ///
    /// - Parameter kind: 要讀取的主檔種類
    /// - Returns: 只包含指定種類的目錄
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchItems: FetchItems

    /// 新增主檔，付款方式同名時覆寫旗標
    ///
    /// - Parameters:
    ///   - kind: 要新增的主檔種類
    ///   - addition: 名稱與付款方式旗標
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var addItem: AddItem

    /// 刪除指定名稱的主檔，不存在時保留原資料
    ///
    /// - Parameters:
    ///   - kind: 要刪除的主檔種類
    ///   - name: 要刪除的名稱
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var removeItem: RemoveItem

    /// 在同一交易內改名主檔與引用訂單，付款方式撞名時合併旗標
    ///
    /// - Parameters:
    ///   - kind: 要改名的主檔種類
    ///   - rename: 原名稱與尚未去除前後空白的新名稱
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var renameItem: RenameItem

    /// 計算目前使用指定付款方式的訂單筆數
    ///
    /// - Parameter paymentMethod: 要查詢的付款方式名稱
    /// - Returns: 資料庫內符合名稱的訂單筆數
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var countOrders: CountOrders

    /// 在同一交易內編輯付款方式，並重算當下引用原名稱的訂單
    ///
    /// - Parameters:
    ///   - originalName: 原付款方式名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式旗標
    /// - Returns: 寫回的訂單，不包含照片；空白新名稱回傳空陣列
    /// - Throws: 查詢、訂單轉換或儲存失敗時丟出 `PersistenceError`
    var applyPaymentMethodEdit: ApplyPaymentMethodEdit
}

// MARK: - Nested Types

extension LookupService {

    /// `fetchItems` 的函式型別
    typealias FetchItems = @Sendable (
        _ kind: LookupKind
    ) async throws(PersistenceError) -> LookupCatalog

    /// `addItem` 的函式型別
    typealias AddItem = @Sendable (
        _ kind: LookupKind,
        _ addition: LookupItemAddition
    ) async throws(PersistenceError) -> Void

    /// `removeItem` 的函式型別
    typealias RemoveItem = @Sendable (
        _ kind: LookupKind,
        _ name: String
    ) async throws(PersistenceError) -> Void

    /// `renameItem` 的函式型別
    typealias RenameItem = @Sendable (
        _ kind: LookupKind,
        _ rename: LookupItemRename
    ) async throws(PersistenceError) -> Void

    /// `countOrders` 的函式型別
    typealias CountOrders = @Sendable (
        _ paymentMethod: String
    ) async throws(PersistenceError) -> Int

    /// `applyPaymentMethodEdit` 的函式型別
    typealias ApplyPaymentMethodEdit = @Sendable (
        _ originalName: String,
        _ newName: String,
        _ flags: PaymentMethodFlags
    ) async throws(PersistenceError) -> [LedgerOrder]
}

// MARK: - Internal Method

extension LookupService {

    /// 依主檔種類讀取自然語言排序的名稱與旗標
    ///
    /// - Parameters:
    ///   - kind: 要讀取的主檔種類
    ///   - context: 本次讀取使用的持久化 `context`
    /// - Returns: 只填入指定種類的主檔目錄
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchItems(
        _ kind: LookupKind,
        in context: ModelContext
    ) throws(PersistenceError) -> LookupCatalog {
        switch kind {
        case .orderSource:
            LookupCatalog(orderSources: try fetchNames(OrderSourceRecord.self, in: context))

        case .category:
            LookupCatalog(categories: try fetchNames(CategoryRecord.self, in: context))

        case .paymentMethod:
            LookupCatalog(paymentMethods: try fetchPaymentMethodInfos(in: context))

        case .reconciliationStatus:
            LookupCatalog(
                reconciliationStatuses: try fetchNames(ReconciliationStatusRecord.self, in: context)
            )
        }
    }

    /// 依主檔種類新增名稱，付款方式使用指定旗標
    ///
    /// - Parameters:
    ///   - kind: 要新增的主檔種類
    ///   - addition: 名稱與付款方式旗標
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addItem(
        _ kind: LookupKind,
        addition: LookupItemAddition,
        in context: ModelContext
    ) throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try addName(OrderSourceRecord.self, rawName: addition.name, in: context)

        case .category:
            try addName(CategoryRecord.self, rawName: addition.name, in: context)

        case .paymentMethod:
            try addPaymentMethod(rawName: addition.name, flags: addition.flags, in: context)

        case .reconciliationStatus:
            try addName(ReconciliationStatusRecord.self, rawName: addition.name, in: context)
        }
    }

    /// 依主檔種類移除符合名稱的全部記錄
    ///
    /// - Parameters:
    ///   - kind: 要刪除的主檔種類
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeItem(
        _ kind: LookupKind,
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try removeName(OrderSourceRecord.self, name: name, in: context)

        case .category:
            try removeName(CategoryRecord.self, name: name, in: context)

        case .paymentMethod:
            try removePaymentMethod(name: name, in: context)

        case .reconciliationStatus:
            try removeName(ReconciliationStatusRecord.self, name: name, in: context)
        }
    }

    /// 讀出全部付款方式資訊並依使用者語言排序
    ///
    /// - Parameter context: 本次讀取使用的持久化 `context`
    /// - Returns: 付款方式資訊陣列，沒有資料時為空陣列
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchPaymentMethodInfos(
        in context: ModelContext
    ) throws(PersistenceError) -> [PaymentMethodInfo] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<PaymentMethodRecord>())
        }
        return records
            .map {
                PaymentMethodInfo(
                    name: $0.name,
                    flags: PaymentMethodFlags(
                        isCardless: $0.isCardless,
                        isBankTransfer: $0.isBankTransfer,
                        isCashOnDelivery: $0.isCashOnDelivery
                    )
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// 刪除符合名稱的全部付款方式記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removePaymentMethod(
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
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

// MARK: - Private Method

private extension LookupService {

    /// 讀出名稱主檔並依使用者語言排序
    ///
    /// - Parameters:
    ///   - recordType: 要讀取的名稱主檔型別
    ///   - context: 本次讀取使用的持久化 `context`
    /// - Returns: 名稱陣列，沒有資料時為空陣列
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchNames<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        in context: ModelContext
    ) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<Record>())
        }
        return records.map(\.name).sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    /// 新增已正規化且尚不存在的主檔名稱
    ///
    /// - Parameters:
    ///   - recordType: 要新增的名稱主檔型別
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addName<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        rawName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if existing == nil {
            context.insert(Record(name: name))
        }
    }

    /// 移除名稱相符的全部主檔記錄
    ///
    /// - Parameters:
    ///   - recordType: 要刪除的名稱主檔型別
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeName<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }
}
