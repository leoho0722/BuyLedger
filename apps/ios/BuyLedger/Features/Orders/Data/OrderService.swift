//
//  OrderService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 訂單讀寫的操作入口；
/// 正式實作在 `liveValue`、Preview 在 `previewValue`、測試預設值在 `testValue`
struct OrderService: Sendable {

    // MARK: - Properties

    /// 讀取目前可顯示的訂單
    ///
    /// - Returns: 依日期由新到舊排序的訂單；不含照片內容，照片另以 `fetchOrderPhotos` 讀取
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `.fetchFailed(underlying: RecordDecodingError)`
    var fetchOrders: FetchOrders

    /// 新增一筆訂單，編號已存在時不覆蓋
    ///
    /// - Parameter order: 要新增的訂單
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    var createOrder: CreateOrder

    /// 新增或更新訂單但保留已存照片
    ///
    /// - Parameter order: 要新增或更新的訂單
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    var saveOrder: SaveOrder

    /// 批次新增或更新訂單但保留已存照片
    ///
    /// - Parameter orders: 要新增或更新的訂單；空陣列不變更資料
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    var saveOrders: SaveOrders

    /// 依訂單編號讀取照片
    ///
    /// - Parameter id: 訂單編號
    /// - Returns: 保持儲存順序的照片；訂單不存在時為空陣列
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`
    var fetchOrderPhotos: FetchOrderPhotos

    /// 新增或更新訂單並以傳入照片覆蓋已存照片
    ///
    /// - Parameter order: 要新增或更新的訂單與完整照片集合
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    var saveOrderPersistingPhotos: SaveOrderPersistingPhotos

    /// 刪除指定編號的訂單
    ///
    /// - Parameter id: 要刪除的訂單編號；不存在時不變更資料
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；儲存失敗時丟出 `.saveFailed(underlying:)`
    var removeOrder: RemoveOrder

    /// 建立合併訂單並標記來源訂單
    ///
    /// - Parameters:
    ///   - newOrder: 合併後要新增的訂單
    ///   - consumedIDs: 要標記為已合併的來源訂單編號
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   儲存失敗時丟出 `.storage(.saveFailed(underlying:))`
    var mergeOrders: MergeOrders
}

// MARK: - Nested Types

extension OrderService {

    /// `fetchOrders` 的函式型別
    typealias FetchOrders = @Sendable () async throws(PersistenceError) -> [LedgerOrder]

    /// `createOrder` 的函式型別
    typealias CreateOrder = @Sendable (_ order: LedgerOrder) async throws(OrderError) -> Void

    /// `saveOrder` 的函式型別
    typealias SaveOrder = @Sendable (_ order: LedgerOrder) async throws(PersistenceError) -> Void

    /// `saveOrders` 的函式型別
    typealias SaveOrders = @Sendable (
        _ orders: [LedgerOrder]
    ) async throws(PersistenceError) -> Void

    /// `fetchOrderPhotos` 的函式型別
    typealias FetchOrderPhotos = @Sendable (
        _ id: LedgerOrder.ID
    ) async throws(PersistenceError) -> [Data]

    /// `saveOrderPersistingPhotos` 的函式型別
    typealias SaveOrderPersistingPhotos = @Sendable (
        _ order: LedgerOrder
    ) async throws(PersistenceError) -> Void

    /// `removeOrder` 的函式型別
    typealias RemoveOrder = @Sendable (_ id: LedgerOrder.ID) async throws(PersistenceError) -> Void

    /// `mergeOrders` 的函式型別
    typealias MergeOrders = @Sendable (
        _ newOrder: LedgerOrder,
        _ consumedIDs: [LedgerOrder.ID]
    ) async throws(OrderError) -> Void

    /// 讀取合併來源訂單所用的函式型別
    typealias ConsumedOrderFetcher = (
        FetchDescriptor<OrderRecord>
    ) throws(PersistenceError) -> [OrderRecord]
}

// MARK: - Internal Method

extension OrderService {

    /// 建立合併訂單並將來源訂單標記為已合併
    ///
    /// - Parameters:
    ///   - newOrder: 合併後的訂單
    ///   - consumedIDs: 被合併消耗的訂單編號
    ///   - context: 本次寫入使用的資料庫 `context`
    ///   - consumedOrderFetcher: 讀取被合併來源訂單的操作
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢合併訂單是否已存在失敗時丟出 `.storage(.fetchFailed(underlying:))`；
    ///   `consumedOrderFetcher` 丟出的 `PersistenceError` 原樣包入 `.storage(_:)`
    static func mergeOrders(
        _ newOrder: LedgerOrder,
        consumedIDs: [LedgerOrder.ID],
        in context: ModelContext,
        consumedOrderFetcher: ConsumedOrderFetcher
    ) throws(OrderError) {
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

// MARK: - DependencyKey

extension OrderService: DependencyKey {

    /// 正式 App 使用注入的資料庫執行訂單操作；
    /// 必須是 computed property，測試才能用 `withDependencies` 換掉 Database
    static var liveValue: Self {
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchOrders: { () throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchOrders(in: context)
                }
            },
            createOrder: { order throws(OrderError) in
                try await database.write { context throws(OrderError) in
                    try Self.createOrder(order, in: context)
                }
            },
            saveOrder: { order throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrder(order, in: context)
                }
            },
            saveOrders: { orders throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrders(orders, in: context)
                }
            },
            fetchOrderPhotos: { id throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchOrderPhotos(id: id, in: context)
                }
            },
            saveOrderPersistingPhotos: { order throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.saveOrderPersistingPhotos(order, in: context)
                }
            },
            removeOrder: { id throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeOrder(id: id, in: context)
                }
            },
            mergeOrders: { newOrder, consumedIDs throws(OrderError) in
                try await database.write { context throws(OrderError) in
                    try Self.mergeOrders(newOrder, consumedIDs: consumedIDs, in: context)
                }
            }
        )
    }

    #if DEBUG

    /// Preview 使用各 Service 共用、只存在記憶體的資料庫執行訂單操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "OrderService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }

    #endif

    /// 測試預設值；每個 closure 都必須由測試明確覆寫
    static var testValue: Self {
        Self(
            fetchOrders: unimplemented("OrderService.fetchOrders", placeholder: []),
            createOrder: unimplemented("OrderService.createOrder"),
            saveOrder: unimplemented("OrderService.saveOrder"),
            saveOrders: unimplemented("OrderService.saveOrders"),
            fetchOrderPhotos: unimplemented("OrderService.fetchOrderPhotos", placeholder: []),
            saveOrderPersistingPhotos: unimplemented("OrderService.saveOrderPersistingPhotos"),
            removeOrder: unimplemented("OrderService.removeOrder"),
            mergeOrders: unimplemented("OrderService.mergeOrders")
        )
    }
}

// MARK: - Private Method

private extension OrderService {

    /// 讀出全部訂單並依日期由新到舊排序
    ///
    /// - Parameter context: 本次讀取使用的資料庫 `context`
    /// - Returns: 不含照片內容的訂單，照片另以 `fetchOrderPhotos` 讀取
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `.fetchFailed(underlying: RecordDecodingError)`
    static func fetchOrders(in context: ModelContext) throws(PersistenceError) -> [LedgerOrder] {
        var descriptor = FetchDescriptor<OrderRecord>(sortBy: [
            SortDescriptor(\.date, order: .reverse),
        ])
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
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        var orders: [LedgerOrder] = []
        orders.reserveCapacity(records.count)
        for record in records {
            orders.append(try record.toDomain(includingPhotos: false))
        }
        return orders
    }

    /// 新增一筆訂單，編號已存在時不覆蓋
    ///
    /// - Parameters:
    ///   - order: 要新增的訂單
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`
    static func createOrder(_ order: LedgerOrder, in context: ModelContext) throws(OrderError) {
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
    ///   - context: 本次寫入使用的資料庫 `context`
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

    /// 在同一次寫入內批次新增或更新訂單；更新既有記錄時保留照片
    ///
    /// - Parameters:
    ///   - orders: 要新增或更新的訂單；空陣列不變更資料
    ///   - context: 本次寫入使用的資料庫 `context`
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

    /// 建立依訂單編號集合查詢的條件
    ///
    /// - Parameter ids: 目標訂單編號集合
    /// - Returns: 僅命中指定編號的查詢條件
    static func idMembershipPredicate(_ ids: Set<String>) -> Predicate<OrderRecord> {
        #Predicate<OrderRecord> { ids.contains($0.id) }
    }

    /// 讀取指定訂單的照片，保持儲存順序
    ///
    /// - Parameters:
    ///   - id: 訂單編號
    ///   - context: 本次讀取使用的資料庫 `context`
    /// - Returns: 訂單照片；訂單不存在時為空陣列
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchOrderPhotos(
        id: LedgerOrder.ID,
        in context: ModelContext
    ) throws(PersistenceError) -> [Data] {
        var descriptor = FetchDescriptor<OrderRecord>(predicate: #Predicate { $0.id == id })
        descriptor.propertiesToFetch = [\.photos]
        return try PersistenceError.mapFetch {
            try context.fetch(descriptor).first?.photos ?? []
        }
    }

    /// 新增或更新訂單，並以傳入照片覆蓋已存照片
    ///
    /// - Parameters:
    ///   - order: 要新增或更新的訂單與完整照片集合
    ///   - context: 本次寫入使用的資料庫 `context`
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
    ///   - context: 本次寫入使用的資料庫 `context`
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

    /// 建立合併訂單並將來源訂單標記為已合併
    ///
    /// - Parameters:
    ///   - newOrder: 合併後的訂單
    ///   - consumedIDs: 被合併消耗的訂單編號
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 編號已存在時丟出 `.identifierCollision(id:)`；
    ///   查詢失敗時丟出 `.storage(.fetchFailed(underlying:))`
    static func mergeOrders(
        _ newOrder: LedgerOrder,
        consumedIDs: [LedgerOrder.ID],
        in context: ModelContext
    ) throws(OrderError) {
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
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 reducer 以 `@Dependency(\.orderService)` 取得的 Order Service
    var orderService: OrderService {
        get { self[OrderService.self] }
        set { self[OrderService.self] = newValue }
    }
}
