//
//  OrderRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 讀取與寫入訂單資料的依賴介面
struct OrderRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前可顯示的訂單
    /// - Returns: 可顯示的訂單
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchOrders: @Sendable () async throws(PersistenceError) -> [LedgerOrder]
    
    /// 建立新訂單；遇到相同編號時整批失敗
    /// - Parameter order: 要建立的新訂單
    /// - Throws: 建立失敗或訂單編號重複時拋出 ``OrderPersistenceError``
    var createOrder: @Sendable (_ order: LedgerOrder) async throws(OrderPersistenceError) -> Void
    
    /// 更新單筆訂單；不覆蓋已存照片
    /// - Parameter order: 要寫入或更新的訂單
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var saveOrder: @Sendable (_ order: LedgerOrder) async throws(PersistenceError) -> Void
    
    /// 批次寫入訂單；更新時不覆蓋已存照片
    /// - Parameter orders: 要寫入或更新的訂單清單
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var saveOrders: @Sendable (_ orders: [LedgerOrder]) async throws(PersistenceError) -> Void
    
    /// 依訂單編號讀取照片；找不到訂單時回傳空陣列
    /// - Parameter id: 訂單編號
    /// - Returns: 訂單照片資料；找不到訂單時為空陣列
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchOrderPhotos: @Sendable (_ id: LedgerOrder.ID) async throws(PersistenceError) -> [Data]
    
    /// 寫入訂單並以 photos 覆蓋已存照片
    /// - Parameter order: 要寫入或更新的訂單
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var saveOrderPersistingPhotos: @Sendable (_ order: LedgerOrder) async throws(PersistenceError) -> Void
    
    /// 刪除指定編號的訂單
    /// - Parameter id: 訂單編號
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removeOrder: @Sendable (_ id: LedgerOrder.ID) async throws(PersistenceError) -> Void
    
    /// 在一次持久化操作中建立合併訂單並標記來源訂單
    /// - Parameters:
    ///   - newOrder: 合併後的新訂單 (含使用者挑選保留的完整照片集合)
    ///   - consumedIDs: 被合併消耗的來源訂單編號清單
    /// - Throws: 建立合併訂單失敗或訂單編號重複時拋出 ``OrderPersistenceError``
    var mergeOrders: @Sendable (
        _ newOrder: LedgerOrder,
        _ consumedIDs: [LedgerOrder.ID]
    ) async throws(OrderPersistenceError) -> Void
    
    /// 將所有訂單的 orderSource 從 oldName 改為 newName
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderSource: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
    
    /// 將所有訂單的 categories 從 oldName 改為 newName
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderCategory: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
    
    /// 將所有訂單的 paymentMethod 從 oldName 改為 newName
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderPaymentMethod: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
    
    /// 將所有訂單的 reconciliationStatus 從 oldName 改為 newName
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderReconciliationStatus: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
    
    /// 將所有訂單的 campaignNames 從 oldName 改為 newName
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renameOrderCampaign: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
}

// MARK: - Nested Types

extension OrderRepository {
    
    /// 持有單一 container 對應的 ``OrderPersistence`` 長命實例
    actor PersistenceInstanceProvider {
        
        // MARK: - Data Properties
        
        /// 用於建立背景 actor 的 SwiftData container
        private let container: ModelContainer
        
        /// 目前已建立的長命 ``OrderPersistence`` 實例，供後續操作重用
        private var cached: OrderPersistence?
        
        /// 建立中的 ``OrderPersistence`` 作業，避免重複建立
        private var creationTask: Task<OrderPersistence, Never>?
        
        // MARK: - Init
        
        /// 以指定的 SwiftData container 建立 provider
        /// - Parameter container: 用於建立背景 actor 的 SwiftData container
        init(container: ModelContainer) {
            self.container = container
        }

        // MARK: - Computed Properties

        /// 取得長命的 ``OrderPersistence`` 實例
        /// - Returns: 對應 container 的 ``OrderPersistence`` 實例
        var instance: OrderPersistence {
            get async {
                if let cached {
                    return cached
                }
                if let creationTask {
                    let created = await creationTask.value
                    cached = created
                    return created
                }

                let container = container
                let task = Task {
                    await MainActor.run {
                        OrderPersistence(modelContainer: container)
                    }
                }
                creationTask = task

                let created = await task.value
                cached = created
                creationTask = nil
                return created
            }
        }
    }
}

// MARK: - Internal Method

extension OrderRepository {
    
    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    /// - Parameters:
    ///   - container: 用於建立背景 actor 的 SwiftData container
    ///   - seedSampleOrdersIfEmpty: 空資料表時是否建立範例訂單
    /// - Returns: 對應的 ``OrderRepository`` 實例
    nonisolated static func live(
        container: ModelContainer,
        seedSampleOrdersIfEmpty: Bool = false
    ) -> OrderRepository {
        let provider = PersistenceInstanceProvider(container: container)
        
        return OrderRepository(
            fetchOrders: { () async throws(PersistenceError) -> [LedgerOrder] in
                let persistence = await provider.instance
                let stored = try await persistence.fetchAll()
                if seedSampleOrdersIfEmpty, stored.isEmpty {
                    _ = try await persistence.seedIfEmpty(with: LedgerOrder.sampleOrders)
                    return try await persistence.fetchAll()
                }
                return stored
            },
            createOrder: { (order: LedgerOrder) async throws(OrderPersistenceError) in
                let persistence = await provider.instance
                try await persistence.create(order)
            },
            saveOrder: { (order: LedgerOrder) async throws(PersistenceError) in
                let persistence = await provider.instance
                try await persistence.update(order)
            },
            saveOrders: { (orders: [LedgerOrder]) async throws(PersistenceError) in
                let persistence = await provider.instance
                try await persistence.upsertAll(orders)
            },
            fetchOrderPhotos: { (id: LedgerOrder.ID) async throws(PersistenceError) -> [Data] in
                let persistence = await provider.instance
                return try await persistence.fetchPhotos(id: id)
            },
            saveOrderPersistingPhotos: { (order: LedgerOrder) async throws(PersistenceError) in
                let persistence = await provider.instance
                try await persistence.updatePersistingPhotos(order)
            },
            removeOrder: { (id: LedgerOrder.ID) async throws(PersistenceError) in
                let persistence = await provider.instance
                try await persistence.delete(id: id)
            },
            mergeOrders: { (newOrder: LedgerOrder, consumedIDs: [LedgerOrder.ID]) async throws(OrderPersistenceError) in
                let persistence = await provider.instance
                try await persistence.mergeOrders(newOrder: newOrder, consumedIDs: consumedIDs)
            },
            renameOrderSource: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await provider.instance
                try await persistence.renameOrderSource(from: oldName, to: trimmedNew)
            },
            renameOrderCategory: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await provider.instance
                try await persistence.renameCategory(from: oldName, to: trimmedNew)
            },
            renameOrderPaymentMethod: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await provider.instance
                try await persistence.renamePaymentMethod(from: oldName, to: trimmedNew)
            },
            renameOrderReconciliationStatus: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await provider.instance
                try await persistence.renameReconciliationStatus(from: oldName, to: trimmedNew)
            },
            renameOrderCampaign: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await provider.instance
                try await persistence.renameCampaign(from: oldName, to: trimmedNew)
            }
        )
    }
}

// MARK: - Dependency Values

extension OrderRepository: DependencyKey {
    
    /// App 執行時使用本機 SwiftData 儲存 (共用 ``PersistenceContainer/shared``)
    nonisolated static let liveValue: OrderRepository = OrderRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫與範例資料
    nonisolated static let previewValue: OrderRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        
        return OrderRepository.live(container: container, seedSampleOrdersIfEmpty: true)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = OrderRepository(
        fetchOrders: { [] },
        createOrder: { _ in },
        saveOrder: { _ in },
        saveOrders: { _ in },
        fetchOrderPhotos: { _ in [] },
        saveOrderPersistingPhotos: { _ in },
        removeOrder: { _ in },
        mergeOrders: { _, _ in },
        renameOrderSource: { _, _ in },
        renameOrderCategory: { _, _ in },
        renameOrderPaymentMethod: { _, _ in },
        renameOrderReconciliationStatus: { _, _ in },
        renameOrderCampaign: { _, _ in }
    )
}
