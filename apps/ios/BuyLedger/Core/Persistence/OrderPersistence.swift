//
//  OrderPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// SwiftData 上對訂單做 CRUD 的背景 actor
@ModelActor
actor OrderPersistence {}

// MARK: - Internal Method

extension OrderPersistence {
    
    /// 建立依日期排序且排除 photos 的查詢描述
    /// - Returns: 不含 `photos` 的 `FetchDescriptor`
    static func fetchAllDescriptor() -> FetchDescriptor<OrderRecord> {
        var descriptor = FetchDescriptor<OrderRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.propertiesToFetch = [
            \.id,
             \.customer,
             \.status,
             \.currency,
             \.date,
             \.items,
             \.itemCost,
             \.domesticShipping,
             \.internationalShipping,
             \.foreignDomesticShipping,
             \.cardFeeRate,
             \.platformFeeRate,
             \.paymentFeeRate,
             \.chargedAmount,
             \.cardlessDeductionAmount,
             \.cardlessSupplementAmount,
             \.orderSource,
             \.categories,
             \.paymentMethod,
             \.notes,
             \.reconciliationStatus,
             \.campaignNames,
             \.paymentReceiptStatus,
             \.isCashOnDelivery,
             \.mergedSourceIDs,
        ]
        return descriptor
    }
    
    /// 建立依訂單編號篩選資料列的 predicate
    /// - Parameter ids: 目標訂單編號集合
    /// - Returns: 僅命中 `id` 屬於 `ids` 之資料列的 predicate
    static func idMembershipPredicate(_ ids: Set<String>) -> Predicate<OrderRecord> {
        #Predicate<OrderRecord> { ids.contains($0.id) }
    }
    
    /// 讀出全部訂單，依日期由新到舊排序
    /// - Returns: 領域型別陣列 (不含照片位元組)
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [LedgerOrder] {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(Self.fetchAllDescriptor())
        }
        
        return records.map { $0.toDomain(includingPhotos: false) }
    }
    
    /// 讀取單筆訂單 (依 id)；不存在回 nil
    /// - Parameter id: 訂單 id
    /// - Returns: 對應的領域訂單 (含照片位元組)；不存在時為 nil
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetch(id: LedgerOrder.ID) throws(PersistenceError) -> LedgerOrder? {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first?.toDomain()
        }
    }
    
    /// 依訂單編號讀取照片，回傳該訂單持久化順序的照片陣列
    /// - Parameter id: 訂單編號
    /// - Returns: 該訂單的照片位元組陣列；訂單不存在時為空陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchPhotos(id: LedgerOrder.ID) throws(PersistenceError) -> [Data] {
        var descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.propertiesToFetch = [\.photos]
        return try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first?.photos ?? []
        }
    }
    
    /// 以「建立」意圖寫入單筆新訂單
    /// - Parameter order: 要建立的新訂單
    /// - Throws: 持久化失敗或編號衝突時拋出 ``OrderPersistenceError``
    func create(_ order: LedgerOrder) throws(OrderPersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        
        let existing: OrderRecord?
        do {
            existing = try PersistenceError.mapFetch {
                try modelContext.fetch(descriptor).first
            }
        } catch {
            throw .storage(error)
        }
        
        guard existing == nil else {
            throw OrderPersistenceError.identifierCollision(id: id)
        }
        
        modelContext.insert(OrderRecord(order: order))
        
        // save 失敗時清除 context 的 pending 變更
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw .storage(error)
        }
    }
    
    /// 以「更新」意圖寫入單筆訂單，**不影響已存照片**
    /// - Parameter order: 來源領域訂單
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func update(_ order: LedgerOrder) throws(PersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.apply(order)
        } else {
            modelContext.insert(OrderRecord(order: order))
        }
        
        // save 失敗時清除 context 的 pending 變更
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    /// 以「更新」意圖寫入單筆訂單，並顯式以 `order.photos` 覆寫已存照片
    /// - Parameter order: 來源領域訂單 (`photos` 須為呼叫端顯式確認過的完整集合)
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func updatePersistingPhotos(_ order: LedgerOrder) throws(PersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        if let existing {
            existing.apply(order)
            existing.photos = order.photos
        } else {
            modelContext.insert(OrderRecord(order: order))
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
    
    /// 以單一 `save()` 批次 upsert 多筆訂單 (依 id)，達成原子落盤
    /// - Parameter orders: 要寫入或更新的訂單；空陣列為 no-op
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func upsertAll(_ orders: [LedgerOrder]) throws(PersistenceError) {
        guard !orders.isEmpty else {
            return
        }
        
        let ids = Set(orders.map(\.id))
        let descriptor = FetchDescriptor<OrderRecord>(predicate: Self.idMembershipPredicate(ids))
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        var recordByID: [String: OrderRecord] = [:]
        for record in existing {
            recordByID[record.id] = record
        }
        
        for order in orders {
            if let record = recordByID[order.id] {
                record.apply(order)
            } else {
                modelContext.insert(OrderRecord(order: order))
            }
        }
        
        // save 失敗時清除 context 的 pending 變更
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    /// 刪除指定 id 的訂單；若不存在不視為錯誤
    /// - Parameter id: 要刪除的訂單編號
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func delete(id: LedgerOrder.ID) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
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
    
    /// 把所有以 `oldName` 為訂單來源的訂單，更名為 `newName`
    /// - Parameters:
    ///   - oldName: 原本的訂單來源名稱
    ///   - newName: 新的訂單來源名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renameOrderSource(from oldName: String, to newName: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.orderSource == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            record.orderSource = newName
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
    
    /// 把所有類別清單包含 `oldName` 的訂單，於陣列內逐元素更名為 `newName`
    /// - Parameters:
    ///   - oldName: 原本的類別名稱
    ///   - newName: 新的類別名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renameCategory(from oldName: String, to newName: String) throws(PersistenceError) {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in records where record.categories.contains(oldName) {
            record.categories = record.categories.map { $0 == oldName ? newName : $0 }
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
    
    /// 把所有以 `oldName` 為付款方式的訂單，更名為 `newName`
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 新的名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renamePaymentMethod(from oldName: String, to newName: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            record.paymentMethod = newName
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
    
    /// 把所有以 `oldName` 為對帳狀態的訂單，更名為 `newName`
    /// - Parameters:
    ///   - oldName: 原本的對帳狀態名稱
    ///   - newName: 新的對帳狀態名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renameReconciliationStatus(from oldName: String, to newName: String) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.reconciliationStatus == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            record.reconciliationStatus = newName
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
    
    /// 將訂單中的 `oldName` 改為 `newName`
    /// - Parameters:
    ///   - oldName: 原本的開團名稱
    ///   - newName: 新的開團名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renameCampaign(from oldName: String, to newName: String) throws(PersistenceError) {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in records where record.campaignNames.contains(oldName) {
            record.campaignNames = record.campaignNames.map { $0 == oldName ? newName : $0 }
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
    
    /// 以單一交易寫入合併訂單並更新來源狀態
    /// - Parameters:
    ///   - newOrder: 合併後的訂單與照片
    ///   - consumedIDs: 被合併的來源訂單編號
    /// - Throws: 持久化失敗或編號衝突時拋出 ``OrderPersistenceError``
    func mergeOrders(
        newOrder: LedgerOrder,
        consumedIDs: [LedgerOrder.ID]
    ) throws(OrderPersistenceError) {
        let newID = newOrder.id
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == newID }
        )
        
        let existing: OrderRecord?
        do {
            existing = try PersistenceError.mapFetch {
                try modelContext.fetch(descriptor).first
            }
        } catch {
            throw .storage(error)
        }
        
        guard existing == nil else {
            throw OrderPersistenceError.identifierCollision(id: newID)
        }
        
        modelContext.insert(OrderRecord(order: newOrder))
        
        let ids = Set(consumedIDs)
        let consumedDescriptor = FetchDescriptor<OrderRecord>(
            predicate: Self.idMembershipPredicate(ids)
        )
        let records: [OrderRecord]
        do {
            records = try PersistenceError.mapFetch {
                try modelContext.fetch(consumedDescriptor)
            }
        } catch {
            modelContext.rollback()
            throw .storage(error)
        }
        for record in records where record.id != newID {
            record.status = .merged
        }
        
        // save 失敗時清除 context 的 pending 變更
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw .storage(error)
        }
    }
    
    /// 資料表為空時寫入範例資料
    /// - Parameter samples: 要 seed 的訂單；通常傳入 ``LedgerOrder/sampleOrders``
    /// - Returns: 是否實際執行了 seed
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    @discardableResult
    func seedIfEmpty(with samples: [LedgerOrder]) throws(PersistenceError) -> Bool {
        var descriptor = FetchDescriptor<OrderRecord>()
        descriptor.fetchLimit = 1
        
        let existing = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        guard existing.isEmpty else {
            return false
        }
        
        for order in samples {
            modelContext.insert(OrderRecord(order: order))
        }
        
        do {
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
        return true
    }
}
