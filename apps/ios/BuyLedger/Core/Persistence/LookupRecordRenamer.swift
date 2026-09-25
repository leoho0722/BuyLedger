//
//  LookupRecordRenamer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/25.
//

import Foundation
import SwiftData

/// 共用只有名稱與付款方式主檔的改名規則
enum LookupRecordRenamer {}

// MARK: - Internal Method

extension LookupRecordRenamer {

    /// 改名只有名稱的主檔；新名稱已存在時合併為一筆
    ///
    /// - Parameters:
    ///   - recordType: 要改名的主檔記錄型別
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱
    ///   - modelContext: 執行改名的持久化 context
    /// - Throws: 查詢記錄失敗時拋出 `PersistenceError.fetchFailed`
    static func rename<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        from oldName: String,
        to newName: String,
        in modelContext: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(oldName))
        let oldRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(oldDescriptor)
        }
        for record in oldRecords {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(newName))
        let existingNew = try PersistenceError.mapFetch {
            try modelContext.fetch(newDescriptor).first
        }
        guard existingNew == nil else {
            return
        }

        modelContext.insert(Record(name: newName))
    }

    /// 改名付款方式並合併來源與既有目標的旗標
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱
    ///   - modelContext: 執行改名的持久化 context
    /// - Throws: 查詢記錄失敗時拋出 `PersistenceError.fetchFailed`
    static func renamePaymentMethod(
        from oldName: String,
        to newName: String,
        in modelContext: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        let oldRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(oldDescriptor)
        }
        let preservedFlags = PaymentMethodFlags(
            isCardless: oldRecords.contains { $0.isCardless },
            isBankTransfer: oldRecords.contains { $0.isBankTransfer },
            isCashOnDelivery: oldRecords.contains { $0.isCashOnDelivery }
        )
        for record in oldRecords {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(newDescriptor).first
        }
        guard let existing else {
            modelContext.insert(
                PaymentMethodRecord(
                    name: newName,
                    isCardless: preservedFlags.isCardless,
                    isBankTransfer: preservedFlags.isBankTransfer,
                    isCashOnDelivery: preservedFlags.isCashOnDelivery
                )
            )
            return
        }

        if preservedFlags.isCardless {
            existing.isCardless = true
        }
        if preservedFlags.isBankTransfer {
            existing.isBankTransfer = true
        }
        if preservedFlags.isCashOnDelivery {
            existing.isCashOnDelivery = true
        }
    }
}
