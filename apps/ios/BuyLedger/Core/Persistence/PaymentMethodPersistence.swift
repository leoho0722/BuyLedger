//
//  PaymentMethodPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// 在背景 actor 中讀寫付款方式資料
@ModelActor
actor PaymentMethodPersistence {}

// MARK: - Internal Method

extension PaymentMethodPersistence {

    /// 讀出全部付款方式名稱，依使用者語言排序
    /// - Returns: 付款方式名稱陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [String] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map { $0.name }
            .sorted { left, right in
                left.localizedStandardCompare(right) == .orderedAscending
            }
    }

    /// 讀出全部付款方式與分類旗標，依使用者語言排序
    /// - Returns: 付款方式資訊陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAllInfos() throws(PersistenceError) -> [PaymentMethodInfo] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map { record in
                PaymentMethodInfo(
                    name: record.name,
                    flags: PaymentMethodFlags(
                        isCardless: record.isCardless,
                        isBankTransfer: record.isBankTransfer,
                        isCashOnDelivery: record.isCashOnDelivery
                    )
                )
            }
            .sorted { left, right in
                left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
    }

    /// 寫入或更新付款方式及其旗標
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由呼叫端完成去除前後空白)
    ///   - flags: 付款方式分類旗標
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func upsert(
        name: String,
        flags: PaymentMethodFlags
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.isCardless = flags.isCardless
            existing.isBankTransfer = flags.isBankTransfer
            existing.isCashOnDelivery = flags.isCashOnDelivery
        } else {
            modelContext.insert(
                PaymentMethodRecord(
                    name: name,
                    isCardless: flags.isCardless,
                    isBankTransfer: flags.isBankTransfer,
                    isCashOnDelivery: flags.isCashOnDelivery
                )
            )
        }
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// 刪除指定名稱的付款方式；不存在時不做任何事
    /// - Parameter name: 付款方式名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func delete(name: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            modelContext.delete(record)
        }

        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// 將付款方式更名；同名時合併，關聯訂單由呼叫端處理
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱 (由呼叫端完成去除前後空白)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func rename(from oldName: String, to newName: String) throws(PersistenceError) {
        try LookupRecordRenamer.renamePaymentMethod(
            from: oldName,
            to: newName,
            in: modelContext
        )

        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// 在一次交易中更新付款方式與受影響訂單
    /// - Parameters:
    ///   - oldName: 原本的付款方式名稱
    ///   - newName: 新的付款方式名稱
    ///   - flags: 付款方式分類旗標
    ///   - orders: 已完成正規化的受影響訂單
    /// - Throws: 主檔或訂單寫入失敗時拋出 ``PaymentMethodPersistenceError``
    func applyEdit(
        from oldName: String,
        to newName: String,
        flags: PaymentMethodFlags,
        orders: [LedgerOrder]
    ) throws(PaymentMethodPersistenceError) {
        do throws(PaymentMethodPersistenceError) {
            let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
                predicate: #Predicate { $0.name == oldName }
            )
            let oldRecords = try mapFetch {
                try modelContext.fetch(oldDescriptor)
            }

            if oldName == newName {
                if let existing = oldRecords.first {
                    existing.isCardless = flags.isCardless
                    existing.isBankTransfer = flags.isBankTransfer
                    existing.isCashOnDelivery = flags.isCashOnDelivery
                } else {
                    modelContext.insert(
                        PaymentMethodRecord(
                            name: newName,
                            isCardless: flags.isCardless,
                            isBankTransfer: flags.isBankTransfer,
                            isCashOnDelivery: flags.isCashOnDelivery
                        )
                    )
                }
            } else {
                for record in oldRecords {
                    modelContext.delete(record)
                }

                let newDescriptor = FetchDescriptor<PaymentMethodRecord>(
                    predicate: #Predicate { $0.name == newName }
                )
                let existing = try mapFetch {
                    try modelContext.fetch(newDescriptor).first
                }
                if let existing {
                    // 編輯設定可取消原有旗標。
                    existing.isCardless = flags.isCardless
                    existing.isBankTransfer = flags.isBankTransfer
                    existing.isCashOnDelivery = flags.isCashOnDelivery
                } else {
                    modelContext.insert(
                        PaymentMethodRecord(
                            name: newName,
                            isCardless: flags.isCardless,
                            isBankTransfer: flags.isBankTransfer,
                            isCashOnDelivery: flags.isCashOnDelivery
                        )
                    )
                }
            }

            let orderIDs = Set(orders.map(\.id))
            let orderDescriptor = FetchDescriptor<OrderRecord>(
                predicate: #Predicate { orderIDs.contains($0.id) }
            )
            let orderRecords = try mapFetch {
                try modelContext.fetch(orderDescriptor)
            }
            var recordByID: [LedgerOrder.ID: OrderRecord] = [:]
            for record in orderRecords {
                recordByID[record.id] = record
            }
            for order in orders {
                guard let record = recordByID[order.id] else {
                    throw PaymentMethodPersistenceError.orderNotFound(id: order.id)
                }
                record.apply(order)
            }

            try mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// 設定指定付款方式的 `isCardless` 旗標；若該名稱不在主檔則先建立記錄
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由呼叫端完成去除前後空白)
    ///   - isCardless: 是否屬於無卡類付款方式
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func setIsCardless(name: String, isCardless: Bool) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.isCardless = isCardless
        } else {
            modelContext.insert(PaymentMethodRecord(name: name, isCardless: isCardless))
        }

        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

// MARK: - Private Method

private extension PaymentMethodPersistence {

    /// 將付款方式讀取失敗轉成付款方式持久化錯誤
    /// - Parameter operation: 要執行的讀取動作
    /// - Returns: 讀取動作的結果
    /// - Throws: operation 失敗時拋出 ``PaymentMethodPersistenceError``
    func mapFetch<Value>(
        _ operation: () throws(any Error) -> Value
    ) throws(PaymentMethodPersistenceError) -> Value {
        do {
            return try PersistenceError.mapFetch {
                try operation()
            }
        } catch {
            throw .storage(error)
        }
    }

    /// 將付款方式寫入失敗轉成付款方式持久化錯誤
    /// - Parameter operation: 要執行的寫入動作
    /// - Throws: operation 失敗時拋出 ``PaymentMethodPersistenceError``
    func mapSave(_ operation: () throws(any Error) -> Void) throws(PaymentMethodPersistenceError) {
        do {
            try PersistenceError.mapSave(operation)
        } catch {
            throw .storage(error)
        }
    }
}
