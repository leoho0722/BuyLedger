//
//  OrderService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

/// 訂單讀寫的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct OrderService: Sendable {

    // MARK: - Properties

    /// 讀取目前可顯示的訂單
    ///
    /// - Returns: 不含照片位元組且依日期由新到舊排序的訂單
    /// - Throws: 查詢失敗時丟出 `.fetchFailed(underlying:)`；
    ///   資料解碼失敗時丟出 `.fetchFailed(underlying: RecordDecodingError)`
    var fetchOrders: FetchOrders

    /// 以建立意圖新增訂單
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

    /// 讀取合併來源訂單的同步操作型別
    typealias ConsumedOrderFetcher = (
        FetchDescriptor<OrderRecord>
    ) throws(PersistenceError) -> [OrderRecord]
}
