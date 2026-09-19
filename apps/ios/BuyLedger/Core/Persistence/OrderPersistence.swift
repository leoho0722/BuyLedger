//
//  OrderPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/05/02.
//

import Foundation
import SwiftData

/// 在背景 actor 中讀寫訂單資料
@ModelActor
actor OrderPersistence {

    /// 來源訂單查詢的可注入實作；未提供時使用目前的 model context
    typealias ConsumedOrderFetcher =
        @Sendable (FetchDescriptor<OrderRecord>) throws(any Error) -> [OrderRecord]

    /// 測試或替代儲存實作使用的來源訂單查詢
    private var consumedOrderFetcher: ConsumedOrderFetcher?

    /// 建立可注入來源訂單查詢的 persistence
    ///
    /// - Parameters:
    ///   - modelContainer: persistence 使用的 model container
    ///   - consumedOrderFetcher: 來源訂單查詢的替代實作
    init(
        modelContainer: ModelContainer,
        consumedOrderFetcher: @escaping ConsumedOrderFetcher
    ) {
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        self.consumedOrderFetcher = consumedOrderFetcher
    }
}

// MARK: - Internal Method

extension OrderPersistence {

    /// 讀出全部訂單，依日期由新到舊排序
    ///
    /// - Returns: 領域型別陣列 (不含照片位元組)
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetchAll() throws(PersistenceError) -> [LedgerOrder] {
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(Self.fetchAllDescriptor())
        }

        var orders: [LedgerOrder] = []
        orders.reserveCapacity(records.count)
        for record in records {
            orders.append(try record.toDomain(includingPhotos: false))
        }
        return orders
    }

    /// 讀取單筆訂單 (依 id)；不存在回 nil
    ///
    /// - Parameter id: 訂單 id
    /// - Returns: 對應的領域訂單 (含照片位元組)；不存在時為 nil
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    func fetch(id: LedgerOrder.ID) throws(PersistenceError) -> LedgerOrder? {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.id == id }
        )
        let record = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor).first
        }
        guard let record else {
            return nil
        }
        return try record.toDomain()
    }

    /// 依訂單編號讀取照片，回傳該訂單持久化順序的照片陣列
    ///
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
    ///
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

        let insertedRecord = OrderRecord(order: order)
        modelContext.insert(insertedRecord)

        do throws(PersistenceError) {
            try performWithRollback(
                insertedRecords: [insertedRecord]
            ) { () throws(PersistenceError) in
                try PersistenceError.mapSave {
                    try modelContext.save()
                }
            }
        } catch {
            throw .storage(error)
        }
    }

    /// 以「更新」意圖寫入單筆訂單，**不影響已存照片**
    ///
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
        var insertedRecords: [OrderRecord] = []
        if let existing {
            existing.apply(order)
        } else {
            let insertedRecord = OrderRecord(order: order)
            modelContext.insert(insertedRecord)
            insertedRecords = [insertedRecord]
        }

        try performWithRollback(insertedRecords: insertedRecords) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 以「更新」意圖寫入單筆訂單，並顯式以 `order.photos` 覆寫已存照片
    ///
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
        var insertedRecords: [OrderRecord] = []
        if let existing {
            existing.apply(order)
            existing.photos = order.photos
        } else {
            let insertedRecord = OrderRecord(order: order)
            modelContext.insert(insertedRecord)
            insertedRecords = [insertedRecord]
        }

        try performWithRollback(insertedRecords: insertedRecords) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 以單一 `save()` 批次 upsert 多筆訂單 (依 id)，達成原子落盤
    ///
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

        var insertedRecords: [OrderRecord] = []
        for order in orders {
            if let record = recordByID[order.id] {
                record.apply(order)
            } else {
                let insertedRecord = OrderRecord(order: order)
                modelContext.insert(insertedRecord)
                insertedRecords.append(insertedRecord)
            }
        }

        try performWithRollback(insertedRecords: insertedRecords) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 刪除指定 id 的訂單；若不存在不視為錯誤
    ///
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

        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 把所有以 `oldName` 為訂單來源的訂單，更名為 `newName`
    ///
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
        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 把所有類別清單包含 `oldName` 的訂單，於陣列內逐元素更名為 `newName`
    ///
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
        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 把所有以 `oldName` 為付款方式的訂單，更名為 `newName`
    ///
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
        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 把所有以 `oldName` 為對帳狀態的訂單，更名為 `newName`
    ///
    /// - Parameters:
    ///   - oldName: 原本的對帳狀態名稱
    ///   - newName: 新的對帳狀態名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    func renameReconciliationStatus(
        from oldName: String,
        to newName: String
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.reconciliationStatus == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in records {
            record.reconciliationStatus = newName
        }
        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 將訂單中的 `oldName` 改為 `newName`
    ///
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
        try performWithRollback(insertedRecords: []) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
    }

    /// 以單一交易寫入合併訂單並更新來源狀態
    ///
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

        let insertedRecord = OrderRecord(order: newOrder)
        modelContext.insert(insertedRecord)

        let ids = Set(consumedIDs)
        let consumedPredicate = Self.idMembershipPredicate(ids)
        let consumedDescriptor = FetchDescriptor<OrderRecord>(predicate: consumedPredicate)
        let records: [OrderRecord]
        do throws(PersistenceError) {
            records = try PersistenceError.mapFetch {
                try fetchConsumedOrderRecords(consumedDescriptor)
            }
        } catch {
            modelContext.rollback()
            throw .storage(error)
        }
        for record in records where record.id != newID {
            record.status = .merged
        }

        do throws(PersistenceError) {
            try performWithRollback(
                insertedRecords: [insertedRecord]
            ) { () throws(PersistenceError) in
                try PersistenceError.mapSave {
                    try modelContext.save()
                }
            }
        } catch {
            throw .storage(error)
        }
    }

    /// 資料表為空時寫入範例資料
    ///
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

        var insertedRecords: [OrderRecord] = []
        for order in samples {
            let insertedRecord = OrderRecord(order: order)
            modelContext.insert(insertedRecord)
            insertedRecords.append(insertedRecord)
        }

        try performWithRollback(insertedRecords: insertedRecords) { () throws(PersistenceError) in
            try PersistenceError.mapSave {
                try modelContext.save()
            }
        }
        return true
    }
}

// MARK: - Private Method

private extension OrderPersistence {

    /// 建立依日期排序且排除照片的查詢描述
    /// - Returns: 不含照片的 `FetchDescriptor`
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

    /// 建立依訂單編號篩選資料列的條件
    /// - Parameter ids: 目標訂單編號集合
    /// - Returns: 僅命中指定訂單編號的 `Predicate`
    static func idMembershipPredicate(_ ids: Set<String>) -> Predicate<OrderRecord> {
        #Predicate<OrderRecord> { ids.contains($0.id) }
    }

    /// 讀取合併來源訂單；預設直接使用 model context
    ///
    /// - Parameter descriptor: 來源訂單的查詢描述
    /// - Returns: 符合查詢的來源訂單記錄
    /// - Throws: 來源訂單查詢失敗時拋出原始錯誤
    func fetchConsumedOrderRecords(
        _ descriptor: FetchDescriptor<OrderRecord>
    ) throws(any Error) -> [OrderRecord] {
        if let consumedOrderFetcher {
            return try consumedOrderFetcher(descriptor)
        }
        return try modelContext.fetch(descriptor)
    }

    /// 執行寫入；失敗時清理本次插入的記錄並保留原始錯誤
    ///
    /// - Parameters:
    ///   - insertedRecords: 這次操作剛插入、尚未成功落盤的記錄
    ///   - operation: 要執行的持久化操作
    /// - Returns: operation 成功時回傳的結果
    /// - Throws: 原始持久化操作失敗時拋出原始錯誤
    func performWithRollback<Result>(
        insertedRecords: [OrderRecord],
        operation: () throws(PersistenceError) -> Result
    ) throws(PersistenceError) -> Result {
        do throws(PersistenceError) {
            return try operation()
        } catch let originalError {
            // 清理失敗不能覆蓋原始寫入錯誤
            try? rollbackPendingOrderRecords(insertedRecords: insertedRecords)
            throw originalError
        }
    }

    /// 清除 save 失敗後仍留在長命 context 的新訂單記錄
    ///
    /// - Parameter insertedRecords: 這次操作剛插入、尚未成功落盤的記錄
    /// - Throws: 清除殘留記錄時讀取持久化資料失敗
    /// - Note: 先保留本次插入的 id，回滾後直接刪除記錄實例
    ///   再查詢同 id 的殘留記錄並移除
    func rollbackPendingOrderRecords(insertedRecords: [OrderRecord]) throws(PersistenceError) {
        let insertedIDs = Set(insertedRecords.map(\.id))
        modelContext.rollback()
        for record in insertedRecords {
            modelContext.delete(record)
        }
        modelContext.processPendingChanges()

        guard !insertedIDs.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: Self.idMembershipPredicate(insertedIDs)
        )
        let residualRecords = try PersistenceError.mapFetch {
            try modelContext.fetch(descriptor)
        }
        for record in residualRecords {
            modelContext.delete(record)
        }
        modelContext.processPendingChanges()
    }
}
