//
//  OrderService+Writes.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

// MARK: - Internal Method

extension OrderService {

    /// 以建立意圖新增訂單並拒絕重複編號
    ///
    /// - Parameters:
    ///   - order: 要新增的訂單
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`
    static func createOrder(
        _ order: LedgerOrder,
        in context: ModelContext
    ) throws(OrderPersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == id })
        let existing: OrderRecord?
        do {
            existing = try PersistenceError.mapFetch {
                try context.fetch(descriptor).first
            }
        } catch {
            throw .storage(error)
        }
        guard existing == nil else {
            throw .identifierCollision(id: id)
        }
        context.insert(OrderRecord(order: order))
    }

    /// 新增或更新訂單，更新時保留已存照片
    ///
    /// - Parameters:
    ///   - order: 要新增或更新的訂單
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveOrder(_ order: LedgerOrder, in context: ModelContext) throws(PersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == id })
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.apply(order)
        } else {
            context.insert(OrderRecord(order: order))
        }
    }

    /// 以單一交易批次新增或更新訂單；更新既有記錄時保留照片
    ///
    /// - Parameters:
    ///   - orders: 要新增或更新的訂單；空陣列不變更資料
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveOrders(
        _ orders: [LedgerOrder],
        in context: ModelContext
    ) throws(PersistenceError) {
        guard !orders.isEmpty else {
            return
        }
        let ids = Set(orders.map(\.id))
        let descriptor = FetchDescriptor<OrderRecord>(predicate: idMembershipPredicate(ids))
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        var recordByID: [String: OrderRecord] = [:]
        for record in records {
            recordByID[record.id] = record
        }
        for order in orders {
            if let record = recordByID[order.id] {
                record.apply(order)
            } else {
                context.insert(OrderRecord(order: order))
            }
        }
    }

    /// 新增或更新訂單，並以傳入照片覆蓋已存照片
    ///
    /// - Parameters:
    ///   - order: 要新增或更新的訂單與完整照片集合
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func saveOrderPersistingPhotos(
        _ order: LedgerOrder,
        in context: ModelContext
    ) throws(PersistenceError) {
        let id = order.id
        let descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == id })
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.apply(order)
            existing.photos = order.photos
        } else {
            context.insert(OrderRecord(order: order))
        }
    }

    /// 刪除指定編號的所有訂單記錄
    ///
    /// - Parameters:
    ///   - id: 要刪除的訂單編號
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeOrder(id: LedgerOrder.ID, in context: ModelContext) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == id })
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }

    /// 使用正式持久化查詢建立合併訂單並將來源訂單標記為已合併
    ///
    /// - Parameters:
    ///   - newOrder: 合併後的訂單
    ///   - consumedIDs: 被合併消耗的訂單編號
    ///   - context: 本次交易使用的持久化 context
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`
    static func mergeOrders(
        _ newOrder: LedgerOrder,
        consumedIDs: [LedgerOrder.ID],
        in context: ModelContext
    ) throws(OrderPersistenceError) {
        try mergeOrders(
            newOrder,
            consumedIDs: consumedIDs,
            in: context
        ) { descriptor throws(PersistenceError) in
            try PersistenceError.mapFetch {
                try context.fetch(descriptor)
            }
        }
    }

    /// 建立合併訂單並將來源訂單標記為已合併
    ///
    /// - Parameters:
    ///   - newOrder: 合併後的訂單
    ///   - consumedIDs: 被合併消耗的訂單編號
    ///   - context: 本次交易使用的持久化 context
    ///   - consumedOrderFetcher: 讀取被合併來源訂單的操作
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢合併訂單是否已存在失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   `consumedOrderFetcher` 拋出的 `PersistenceError` 原樣包入 `.storage(_:)`
    static func mergeOrders(
        _ newOrder: LedgerOrder,
        consumedIDs: [LedgerOrder.ID],
        in context: ModelContext,
        consumedOrderFetcher: ConsumedOrderFetcher
    ) throws(OrderPersistenceError) {
        let newID = newOrder.id
        let descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == newID })
        let existing: OrderRecord?
        do {
            existing = try PersistenceError.mapFetch {
                try context.fetch(descriptor).first
            }
        } catch {
            throw .storage(error)
        }
        guard existing == nil else {
            throw .identifierCollision(id: newID)
        }

        context.insert(OrderRecord(order: newOrder))
        let consumedDescriptor = FetchDescriptor<OrderRecord>(
            predicate: idMembershipPredicate(Set(consumedIDs))
        )
        let records: [OrderRecord]
        do {
            records = try consumedOrderFetcher(consumedDescriptor)
        } catch {
            throw .storage(error)
        }
        for record in records where record.id != newID {
            record.status = .merged
        }
    }
}

// MARK: - Private Method

private extension OrderService {

    /// 建立依訂單編號集合查詢的條件
    ///
    /// - Parameter ids: 目標訂單編號集合
    /// - Returns: 僅命中指定編號的查詢條件
    static func idMembershipPredicate(_ ids: Set<String>) -> Predicate<OrderRecord> {
        #Predicate<OrderRecord> { ids.contains($0.id) }
    }
}
