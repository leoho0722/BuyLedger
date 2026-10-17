//
//  LookupService+PaymentMethods.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import SwiftData

// MARK: - Internal Method

extension LookupService {

    /// 寫入或更新付款方式，覆寫同名記錄的全部旗標
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - flags: 付款方式分類旗標
    ///   - context: 本次交易使用的持久化 `context`
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

    /// 計算資料庫內使用指定付款方式的訂單數量
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - context: 本次讀取使用的持久化 `context`
    /// - Returns: 名稱相符的訂單筆數
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func countOrders(
        paymentMethod: String,
        in context: ModelContext
    ) throws(PersistenceError) -> Int {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == paymentMethod }
        )
        return try PersistenceError.mapFetch {
            try context.fetchCount(descriptor)
        }
    }

    /// 在同一交易內覆寫付款方式主檔，重算當下引用原名稱的訂單
    ///
    /// - Parameters:
    ///   - oldName: 原付款方式名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式旗標
    ///   - context: 本次交易使用的持久化 `context`
    /// - Returns: 寫回的訂單，不包含照片
    /// - Throws: 查詢或訂單轉換失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyPaymentMethodEdit(
        from oldName: String,
        to newName: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) -> [LedgerOrder] {
        guard !newName.isEmpty else {
            return []
        }
        if oldName != newName {
            try removePaymentMethod(name: oldName, in: context)
        }
        try upsert(name: newName, flags: flags, in: context)

        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        var updatedOrders: [LedgerOrder] = []
        for record in records {
            let order = try record.toDomain(includingPhotos: false)
                .renamingPaymentMethod(to: newName)
                .applyingPaymentMethodFlags(flags)
            record.apply(order)
            updatedOrders.append(order)
        }
        return updatedOrders
    }

    /// 在同一交易內改名付款方式並合併主檔旗標
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renamePaymentMethod(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        let oldRecords = try PersistenceError.mapFetch {
            try context.fetch(oldDescriptor)
        }
        let mergedFlags = PaymentMethodFlags(
            isCardless: oldRecords.contains(where: \.isCardless),
            isBankTransfer: oldRecords.contains(where: \.isBankTransfer),
            isCashOnDelivery: oldRecords.contains(where: \.isCashOnDelivery)
        )
        for record in oldRecords {
            context.delete(record)
        }

        let newDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(newDescriptor).first
        }
        if let existing {
            existing.isCardless = existing.isCardless || mergedFlags.isCardless
            existing.isBankTransfer = existing.isBankTransfer || mergedFlags.isBankTransfer
            existing.isCashOnDelivery = existing.isCashOnDelivery || mergedFlags.isCashOnDelivery
        } else {
            context.insert(
                PaymentMethodRecord(
                    name: newName,
                    isCardless: mergedFlags.isCardless,
                    isBankTransfer: mergedFlags.isBankTransfer,
                    isCashOnDelivery: mergedFlags.isCashOnDelivery
                )
            )
        }

        let orderDescriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        let orderRecords = try PersistenceError.mapFetch {
            try context.fetch(orderDescriptor)
        }
        for record in orderRecords {
            record.paymentMethod = newName
        }
    }
}

// MARK: - Private Method

private extension LookupService {

    /// 依指定旗標新增付款方式，或更新同名記錄
    ///
    /// - Parameters:
    ///   - name: 已去除前後空白的付款方式名稱
    ///   - flags: 要寫入的付款方式旗標
    ///   - context: 本次交易使用的持久化 `context`
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
}
