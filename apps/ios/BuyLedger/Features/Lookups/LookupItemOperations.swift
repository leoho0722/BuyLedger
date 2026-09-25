//
//  LookupItemOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 分派四種主檔的讀取、新增、刪除與改名操作
struct LookupItemOperations: Sendable {

    // MARK: - Properties

    /// 商品類別主檔資料來源
    let categoryRepository: CategoryRepository

    /// 訂單資料來源；改名時與主檔一起更新
    let orderRepository: OrderRepository

    /// 訂單來源主檔資料來源
    let orderSourceRepository: OrderSourceRepository

    /// 付款方式主檔資料來源
    let paymentMethodRepository: PaymentMethodRepository

    /// 對帳狀態主檔資料來源
    let reconciliationStatusRepository: ReconciliationStatusRepository
}

// MARK: - Internal Method

extension LookupItemOperations {

    /// 載入指定種類的主檔目錄
    ///
    /// - Parameter kind: 要載入的主檔種類
    /// - Returns: 載入結果 action 的 effect
    func load(kind: LookupKind) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                let catalog = try await loadItems(kind: kind)
                await send(.itemsResponse(.success(catalog)))
            } catch {
                await send(.itemsResponse(.failure(error)))
            }
        }
    }

    /// 寫入新增項目並送回結果
    ///
    /// - Parameters:
    ///   - addition: 要新增的名稱與旗標
    ///   - kind: 要新增的主檔種類
    /// - Returns: 新增結果 action 的 effect
    func add(
        _ addition: LookupItemAddition,
        kind: LookupKind
    ) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await addItem(addition, kind: kind)
                await send(.addResponse(.success(addition)))
            } catch {
                await send(.addResponse(.failure(error)))
            }
        }
    }

    /// 寫入刪除並送回結果
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - kind: 要刪除的主檔種類
    /// - Returns: 刪除結果 action 的 effect
    func delete(
        name: String,
        kind: LookupKind
    ) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await deleteItem(name: name, kind: kind)
                await send(.deleteResponse(.success(name)))
            } catch {
                await send(.deleteResponse(.failure(error)))
            }
        }
    }

    /// 寫入主檔與訂單改名並送回結果
    ///
    /// - Parameters:
    ///   - rename: 要寫入的新舊名稱
    ///   - kind: 要改名的主檔種類
    /// - Returns: 改名結果 action 的 effect
    func rename(
        _ rename: LookupItemRename,
        kind: LookupKind
    ) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await renameItem(rename, kind: kind)
                await send(.renameResponse(.success(rename)))
            } catch {
                await send(.renameResponse(.failure(error)))
            }
        }
    }
}

// MARK: - Private Method

private extension LookupItemOperations {

    /// 依主檔種類載入對應清單
    ///
    /// - Parameter kind: 要載入的主檔種類
    /// - Returns: 只包含指定種類清單的目錄
    /// - Throws: repository 讀取失敗時拋出 `PersistenceError.fetchFailed`
    func loadItems(kind: LookupKind) async throws(PersistenceError) -> LookupCatalog {
        switch kind {
        case .orderSource:
            return LookupCatalog(
                orderSources: try await orderSourceRepository.fetchOrderSources()
            )

        case .category:
            return LookupCatalog(
                categories: try await categoryRepository.fetchCategories()
            )

        case .paymentMethod:
            let infos = try await paymentMethodRepository.fetchPaymentMethodInfos()
            let sortedInfos = infos.sorted { first, second in
                first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
            return LookupCatalog(paymentMethods: sortedInfos)

        case .reconciliationStatus:
            return LookupCatalog(
                reconciliationStatuses: try await reconciliationStatusRepository
                    .fetchReconciliationStatuses()
            )
        }
    }

    /// 依主檔種類寫入新增項目
    ///
    /// - Parameters:
    ///   - addition: 要新增的名稱與旗標
    ///   - kind: 要新增的主檔種類
    /// - Throws: 檢查既有名稱失敗時拋出 `PersistenceError.fetchFailed`；
    ///   寫入失敗時拋出 `PersistenceError.saveFailed`
    func addItem(
        _ addition: LookupItemAddition,
        kind: LookupKind
    ) async throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try await orderSourceRepository.addOrderSource(addition.name)

        case .category:
            try await categoryRepository.addCategory(addition.name)

        case .paymentMethod:
            try await paymentMethodRepository.addPaymentMethod(addition.name, addition.flags)

        case .reconciliationStatus:
            try await reconciliationStatusRepository.addReconciliationStatus(addition.name)
        }
    }

    /// 依主檔種類寫入刪除
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - kind: 要刪除的主檔種類
    /// - Throws: 查詢要刪除的項目失敗時拋出 `PersistenceError.fetchFailed`；
    ///   刪除失敗時拋出 `PersistenceError.saveFailed`
    func deleteItem(name: String, kind: LookupKind) async throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try await orderSourceRepository.removeOrderSource(name)

        case .category:
            try await categoryRepository.removeCategory(name)

        case .paymentMethod:
            try await paymentMethodRepository.removePaymentMethod(name)

        case .reconciliationStatus:
            try await reconciliationStatusRepository.removeReconciliationStatus(name)
        }
    }

    /// 以單一持久化交易更新主檔與訂單中的名稱
    ///
    /// - Parameters:
    ///   - rename: 要寫入的新舊名稱
    ///   - kind: 要改名的主檔種類
    /// - Throws: 讀取主檔或訂單失敗時拋出 `PersistenceError.fetchFailed`；
    ///   儲存失敗時拋出 `PersistenceError.saveFailed`
    func renameItem(
        _ rename: LookupItemRename,
        kind: LookupKind
    ) async throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try await orderRepository.applyOrderSourceRename(rename.oldName, rename.newName)

        case .category:
            try await orderRepository.applyCategoryRename(rename.oldName, rename.newName)

        case .paymentMethod:
            try await orderRepository.applyPaymentMethodRename(rename.oldName, rename.newName)

        case .reconciliationStatus:
            try await orderRepository.applyReconciliationStatusRename(
                rename.oldName,
                rename.newName
            )
        }
    }
}
