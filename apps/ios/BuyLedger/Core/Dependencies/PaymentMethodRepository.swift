//
//  PaymentMethodRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 付款方式主檔的依賴介面
struct PaymentMethodRepository: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 讀取目前所有付款方式名稱 (已排序)
    /// - Returns: 已排序的付款方式名稱
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchPaymentMethods: @Sendable () async throws(PersistenceError) -> [String]
    
    /// 讀取目前所有付款方式 (含 `isCardless` 旗標，已依名稱排序)
    /// - Returns: 已排序的付款方式資料
    /// - Throws: 讀取持久化資料失敗時拋出 ``PersistenceError``
    var fetchPaymentMethodInfos: @Sendable () async throws(PersistenceError) -> [PaymentMethodInfo]
    
    /// 加入新付款方式；trim 後若空字串視為 no-op
    /// - Parameters:
    ///   - name: 付款方式名稱 (未 trim)
    ///   - isCardless: 是否屬於無卡類
    ///   - isBankTransfer: 是否為銀行轉帳
    ///   - isCashOnDelivery: 是否為貨到付款
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var addPaymentMethod: @Sendable (
        _ name: String,
        _ isCardless: Bool,
        _ isBankTransfer: Bool,
        _ isCashOnDelivery: Bool
    ) async throws(PersistenceError) -> Void
    
    /// 刪除指定名稱的付款方式；不存在視為 no-op
    /// - Parameter name: 要刪除的名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var removePaymentMethod: @Sendable (_ name: String) async throws(PersistenceError) -> Void
    
    /// 更名付款方式；只更新主檔
    /// - Parameters:
    ///   - oldName: 舊名稱
    ///   - newName: 新名稱
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var renamePaymentMethod: @Sendable (
        _ oldName: String,
        _ newName: String
    ) async throws(PersistenceError) -> Void
    
    /// 在一次持久化操作中更新付款方式與受影響訂單
    /// - Parameters:
    ///   - oldName: 原本的付款方式名稱
    ///   - newName: 新的付款方式名稱
    ///   - isCardless: 是否屬於無卡類
    ///   - isBankTransfer: 是否屬於銀行匯款類
    ///   - isCashOnDelivery: 是否屬於貨到付款類
    ///   - orders: 已完成名稱替換與旗標正規化的受影響訂單
    /// - Throws: 主檔或訂單寫入失敗時拋出 ``PaymentMethodPersistenceError``
    var applyPaymentMethodEdit: @Sendable (
        _ oldName: String,
        _ newName: String,
        _ isCardless: Bool,
        _ isBankTransfer: Bool,
        _ isCashOnDelivery: Bool,
        _ orders: [LedgerOrder]
    ) async throws(PaymentMethodPersistenceError) -> Void
    
    /// 設定指定付款方式的 `isCardless` 旗標；若該名稱尚未在主檔則建立記錄
    /// - Parameters:
    ///   - rawName: 要設定的付款方式名稱 (未 trim)
    ///   - isCardless: 是否屬於無卡類
    /// - Throws: 寫入持久化資料失敗時拋出 ``PersistenceError``
    var setPaymentMethodIsCardless: @Sendable (
        _ rawName: String,
        _ isCardless: Bool
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension PaymentMethodRepository {
    
    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container
    /// - Returns: 對應的 ``PaymentMethodRepository`` 實例
    nonisolated static func live(container: ModelContainer) -> PaymentMethodRepository {
        PaymentMethodRepository(
            fetchPaymentMethods: { () async throws(PersistenceError) -> [String] in
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            fetchPaymentMethodInfos: { () async throws(PersistenceError) -> [PaymentMethodInfo] in
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAllInfos()
            },
            addPaymentMethod: { (rawName: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool) async throws(PersistenceError) in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(
                    name: trimmed,
                    isCardless: isCardless,
                    isBankTransfer: isBankTransfer,
                    isCashOnDelivery: isCashOnDelivery
                )
            },
            removePaymentMethod: { (name: String) async throws(PersistenceError) in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(name: name)
            },
            renamePaymentMethod: { (oldName: String, newName: String) async throws(PersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.rename(from: oldName, to: trimmedNew)
            },
            applyPaymentMethodEdit: { (oldName: String, newName: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool, orders: [LedgerOrder]) async throws(PaymentMethodPersistenceError) in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.applyEdit(
                    from: oldName,
                    to: trimmedNew,
                    isCardless: isCardless,
                    isBankTransfer: isBankTransfer,
                    isCashOnDelivery: isCashOnDelivery,
                    orders: orders
                )
            },
            setPaymentMethodIsCardless: { (rawName: String, isCardless: Bool) async throws(PersistenceError) in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return
                }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.setIsCardless(name: trimmed, isCardless: isCardless)
            }
        )
    }
}

// MARK: - Private Method

private extension PaymentMethodRepository {
    
    /// 建立 PaymentMethodPersistence
    /// - Parameter container: 共用的 ``ModelContainer``
    /// - Returns: 對應 container 的 ``PaymentMethodPersistence`` 實例
    static func makePersistence(container: ModelContainer) async -> PaymentMethodPersistence {
        await MainActor.run {
            PaymentMethodPersistence(modelContainer: container)
        }
    }
}

// MARK: - Dependency Values

extension PaymentMethodRepository: DependencyKey {
    
    /// App 執行時使用共用 SwiftData container
    nonisolated static let liveValue: PaymentMethodRepository = PaymentMethodRepository.live(
        container: PersistenceContainer.shared
    )
    
    /// Preview 使用記憶體資料庫
    nonisolated static let previewValue: PaymentMethodRepository = {
        let container = PersistenceContainer.makeInMemory(for: .preview)
        return PaymentMethodRepository.live(container: container)
    }()
    
    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = PaymentMethodRepository(
        fetchPaymentMethods: { [] },
        fetchPaymentMethodInfos: { [] },
        addPaymentMethod: { _, _, _, _ in },
        removePaymentMethod: { _ in },
        renamePaymentMethod: { _, _ in },
        applyPaymentMethodEdit: { _, _, _, _, _, _ in },
        setPaymentMethodIsCardless: { _, _ in }
    )
}
