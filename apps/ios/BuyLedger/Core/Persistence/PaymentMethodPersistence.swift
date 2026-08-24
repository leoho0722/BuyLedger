//
//  PaymentMethodPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 上對付款方式主檔做 CRUD 的背景 actor
@ModelActor
actor PaymentMethodPersistence {}

// MARK: - Internal Method

extension PaymentMethodPersistence {
    
    /// 讀出全部付款方式名稱，依 locale 升冪排序
    /// - Returns: 付款方式名稱陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [String] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        return records
            .map { $0.name }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
    
    /// 讀出全部付款方式 (含分類旗標)，依 locale 升冪排序
    /// - Returns: 付款方式資訊陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAllInfos() throws(PersistenceError) -> [PaymentMethodInfo] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
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
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    /// 寫入或更新付款方式及其旗標
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由 caller 完成 trim)
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
    
    /// 刪除指定名稱的付款方式；不存在時視為 no-op
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
    
    /// 將付款方式更名；同名時合併，訂單 cascade 由 caller 處理
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱 (由 caller 完成 trim)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func rename(from oldName: String, to newName: String) throws(PersistenceError) {
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
        if let existing {
            // 合併時保留任一邊已有的付款旗標。
            if preservedFlags.isCardless {
                existing.isCardless = true
            }
            if preservedFlags.isBankTransfer {
                existing.isBankTransfer = true
            }
            if preservedFlags.isCashOnDelivery {
                existing.isCashOnDelivery = true
            }
        } else {
            modelContext.insert(
                PaymentMethodRecord(
                    name: newName,
                    isCardless: preservedFlags.isCardless,
                    isBankTransfer: preservedFlags.isBankTransfer,
                    isCashOnDelivery: preservedFlags.isCashOnDelivery
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
        do {
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
            guard let error = error as? PaymentMethodPersistenceError else {
                fatalError("PaymentMethodPersistence emitted an unmapped error.")
            }
            throw error
        }
    }
    
    /// 設定指定付款方式的 `isCardless` 旗標；若該名稱不在主檔則先建立記錄
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由 caller 完成 trim)
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
    
    /// 將付款方式操作中的讀取錯誤包成 domain error
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 失敗時拋出 ``PaymentMethodPersistenceError``
    func mapFetch<T>(_ operation: () throws(any Error) -> T) throws(PaymentMethodPersistenceError) -> T {
        do {
            return try PersistenceError.mapFetch {
                try operation()
            }
        } catch {
            throw .storage(error)
        }
    }
    
    /// 將付款方式操作中的寫入錯誤包成 domain error
    /// - Parameter operation: 要執行的操作
    /// - Throws: operation 失敗時拋出 ``PaymentMethodPersistenceError``
    func mapSave(_ operation: () throws(any Error) -> Void) throws(PaymentMethodPersistenceError) {
        do {
            try PersistenceError.mapSave(operation)
        } catch {
            throw .storage(error)
        }
    }
}
