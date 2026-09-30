//
//  PaymentMethodService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 付款方式主檔與關聯訂單的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct PaymentMethodService: Sendable {

    // MARK: - Properties

    /// 讀取目前所有付款方式與旗標並依名稱排序
    ///
    /// - Returns: 已排序的付款方式資訊
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchPaymentMethodInfos: FetchPaymentMethodInfos

    /// 加入或更新付款方式；去除前後空白後若為空字串則不處理
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - flags: 付款方式分類旗標
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var addPaymentMethod: AddPaymentMethod

    /// 刪除指定名稱的付款方式；不存在時不做任何事
    ///
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`；
    ///   儲存失敗時丟出 `PersistenceError.saveFailed(underlying:)`
    var removePaymentMethod: RemovePaymentMethod

    /// 在一次持久化交易中更新付款方式與受影響訂單
    ///
    /// - Parameters:
    ///   - oldName: 原本的付款方式名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式分類旗標
    ///   - orders: 已完成名稱替換與旗標正規化的受影響訂單
    /// - Throws: 找不到訂單時丟出 `PaymentMethodPersistenceError.orderNotFound(id:)`；
    ///   讀取失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    var applyPaymentMethodEdit: ApplyPaymentMethodEdit
}

// MARK: - Nested Types

extension PaymentMethodService {

    /// `fetchPaymentMethodInfos` 的函式型別
    typealias FetchPaymentMethodInfos = @Sendable () async throws(PersistenceError) -> [PaymentMethodInfo]

    /// `addPaymentMethod` 的函式型別
    typealias AddPaymentMethod = @Sendable (
        _ rawName: String,
        _ flags: PaymentMethodFlags
    ) async throws(PersistenceError) -> Void

    /// `removePaymentMethod` 的函式型別
    typealias RemovePaymentMethod = @Sendable (
        _ name: String
    ) async throws(PersistenceError) -> Void

    /// `applyPaymentMethodEdit` 的函式型別
    typealias ApplyPaymentMethodEdit = @Sendable (
        _ oldName: String,
        _ newName: String,
        _ flags: PaymentMethodFlags,
        _ orders: [LedgerOrder]
    ) async throws(PaymentMethodPersistenceError) -> Void
}

// MARK: - Internal Method

extension PaymentMethodService {

    /// 讀出全部付款方式資訊並依使用者語言排序
    ///
    /// - Parameter context: 本次讀取使用的持久化 context
    /// - Returns: 已排序的付款方式資訊
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

    /// 寫入或更新付款方式，覆寫同名記錄的全部旗標
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - flags: 付款方式分類旗標
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addPaymentMethod(
        rawName: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        try upsert(name: name, flags: flags, in: context)
    }

    /// 刪除符合名稱的全部付款方式記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次交易使用的持久化 context
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

    /// 在同一個 `context` 內把付款方式改成新名稱並覆寫旗標，再把受影響訂單換成傳入的內容；新名稱去除空白後為空字串時不處理
    ///
    /// - Parameters:
    ///   - oldName: 原本的付款方式名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式分類旗標
    ///   - orders: 已完成名稱替換與旗標正規化的受影響訂單
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 找不到訂單時丟出 `PaymentMethodPersistenceError.orderNotFound(id:)`；
    ///   讀取失敗時丟出 `.storage(.fetchFailed(underlying:))`
    static func applyPaymentMethodEdit(
        from oldName: String,
        to newName: String,
        flags: PaymentMethodFlags,
        orders: [LedgerOrder],
        in context: ModelContext
    ) throws(PaymentMethodPersistenceError) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        if oldName == trimmedName {
            try wrapStorage { () throws(PersistenceError) in
                try upsert(name: trimmedName, flags: flags, in: context)
            }
        } else {
            let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
                predicate: #Predicate { $0.name == oldName }
            )
            let oldRecords = try wrapStorage { () throws(PersistenceError) in
                try PersistenceError.mapFetch {
                    try context.fetch(oldDescriptor)
                }
            }
            for record in oldRecords {
                context.delete(record)
            }
            try wrapStorage { () throws(PersistenceError) in
                try upsert(name: trimmedName, flags: flags, in: context)
            }
        }

        let orderIDs = Set(orders.map(\.id))
        let orderDescriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { orderIDs.contains($0.id) }
        )
        let orderRecords = try wrapStorage { () throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(orderDescriptor)
            }
        }
        var recordByID: [LedgerOrder.ID: OrderRecord] = [:]
        for record in orderRecords {
            recordByID[record.id] = record
        }
        for order in orders {
            guard let record = recordByID[order.id] else {
                throw .orderNotFound(id: order.id)
            }
            record.apply(order)
        }
    }
}

// MARK: - Private Method

private extension PaymentMethodService {

    /// 依指定旗標新增付款方式，或更新同名記錄
    ///
    /// - Parameters:
    ///   - name: 已去除前後空白的付款方式名稱
    ///   - flags: 要寫入的付款方式旗標
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func upsert(
        name: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.isCardless = flags.isCardless
            existing.isBankTransfer = flags.isBankTransfer
            existing.isCashOnDelivery = flags.isCashOnDelivery
        } else {
            context.insert(
                PaymentMethodRecord(
                    name: name,
                    isCardless: flags.isCardless,
                    isBankTransfer: flags.isBankTransfer,
                    isCashOnDelivery: flags.isCashOnDelivery
                )
            )
        }
    }

    /// 將持久化錯誤包成 `.storage`
    ///
    /// - Parameter operation: 要執行的持久化操作
    /// - Returns: 操作的結果
    /// - Throws: 以 `.storage(_:)` 包裝 `operation` 丟出的 `PersistenceError`；
    ///   本檔呼叫點只會是 `.storage(.fetchFailed(underlying:))`
    static func wrapStorage<Value>(
        _ operation: () throws(PersistenceError) -> Value
    ) throws(PaymentMethodPersistenceError) -> Value {
        do {
            return try operation()
        } catch {
            throw .storage(error)
        }
    }
}
