//
//  OrderService+Renames.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

// MARK: - Internal Method

extension OrderService {

    /// 去除新名稱前後空白，並判斷這次改名需不需要執行
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 尚未去除前後空白的新名稱
    /// - Returns: 去除空白後的新名稱；新名稱為空白或與 `oldName` 相同時為 `nil`
    static func normalizedRenameTarget(oldName: String, newName: String) -> String? {
        let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty, normalizedName != oldName else {
            return nil
        }
        return normalizedName
    }

    /// 在同一交易內改名訂單來源主檔與引用它的訂單
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyOrderSourceRename(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            OrderSourceRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.orderSource == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            record.orderSource = newName
        }
    }

    /// 在同一交易內改名類別主檔與所有訂單中的類別值
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyCategoryRename(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            CategoryRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in records where record.categories.contains(oldName) {
            record.categories = record.categories.map { $0 == oldName ? newName : $0 }
        }
    }

    /// 在同一交易內改名付款方式並合併主檔旗標
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyPaymentMethodRename(
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

    /// 在同一交易內改名對帳狀態主檔與訂單欄位
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyReconciliationStatusRename(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            ReconciliationStatusRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.reconciliationStatus == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            record.reconciliationStatus = newName
        }
    }

    /// 將所有訂單中的開團名稱改為新名稱
    ///
    /// - Parameters:
    ///   - oldName: 原本的開團名稱
    ///   - newName: 已正規化的新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameOrderCampaign(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in records where record.campaignNames.contains(oldName) {
            record.campaignNames = record.campaignNames.map { $0 == oldName ? newName : $0 }
        }
    }
}

// MARK: - Private Method

private extension OrderService {

    /// 改名只有名稱的主檔，目標已存在時只移除來源列
    ///
    /// - Parameters:
    ///   - recordType: 要改名的主檔記錄型別
    ///   - oldName: 原本的名稱
    ///   - newName: 新名稱
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameLookup<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(oldName))
        let oldRecords = try PersistenceError.mapFetch {
            try context.fetch(oldDescriptor)
        }
        for record in oldRecords {
            context.delete(record)
        }

        let newDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(newName))
        let existing = try PersistenceError.mapFetch {
            try context.fetch(newDescriptor).first
        }
        guard existing == nil else {
            return
        }
        context.insert(Record(name: newName))
    }
}
