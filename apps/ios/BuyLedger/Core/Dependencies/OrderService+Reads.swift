//
//  OrderService+Reads.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

// MARK: - Internal Method

extension OrderService {

    /// 讀出全部訂單並依日期由新到舊排序
    ///
    /// - Parameter context: 本次讀取使用的持久化 context
    /// - Returns: 不含照片位元組的領域訂單
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `.fetchFailed(underlying: RecordDecodingError)`
    static func fetchOrders(in context: ModelContext) throws(PersistenceError) -> [LedgerOrder] {
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

    /// 讀取指定訂單的照片，保持儲存順序
    ///
    /// - Parameters:
    ///   - id: 訂單編號
    ///   - context: 本次讀取使用的持久化 context
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
}
