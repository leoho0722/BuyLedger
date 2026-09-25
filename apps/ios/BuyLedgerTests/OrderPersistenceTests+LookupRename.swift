//
//  OrderPersistenceTests+LookupRename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/25.
//

import Foundation
import SwiftData
import Testing

@testable import BuyLedger

// MARK: - Tests

extension OrderPersistenceTests {

    /// 一次交易成功改名商品類別與引用訂單
    ///
    /// - Throws: 測試容器建立或改名寫入失敗時拋出錯誤
    @Test
    func categoryRenameTransactionUpdatesLookupAndOrders() async throws(any Error) {
        // Given
        let originalOrder = Self.makeLookupRenameOrder(id: "LOOKUP-RENAME", categories: ["服飾"])
        let container = try Self.makeLookupRenameContainer(
            categoryNames: ["服飾"],
            orders: [originalOrder]
        )
        let persistence = OrderPersistence(modelContainer: container)
        let ordersBeforeRename = try await persistence.fetchAll()

        // When
        try await persistence.applyCategoryRename(from: "服飾", to: "衣著")

        // Then
        let categories = try await persistence.fetchLookupNamesForTesting(of: CategoryRecord.self)
        let ordersAfterRename = try await persistence.fetchAll()
        #expect(categories == ["衣著"])
        #expect(ordersBeforeRename.first?.categories == ["服飾"])
        #expect(ordersAfterRename.first?.categories == ["衣著"])
    }

    /// 改名到既有類別時合併主檔並只改寫原名稱的訂單
    ///
    /// - Throws: 測試容器建立或改名寫入失敗時拋出錯誤
    @Test
    func categoryRenameOntoExistingNameMergesTheLookup() async throws(any Error) {
        // Given
        let sourceOrder = Self.makeLookupRenameOrder(id: "LOOKUP-SOURCE", categories: ["服飾"])
        let targetOrder = Self.makeLookupRenameOrder(id: "LOOKUP-TARGET", categories: ["衣著"])
        let container = try Self.makeLookupRenameContainer(
            categoryNames: ["服飾", "衣著"],
            orders: [sourceOrder, targetOrder]
        )
        let persistence = OrderPersistence(modelContainer: container)

        // When
        try await persistence.applyCategoryRename(from: "服飾", to: "衣著")

        // Then
        let categories = try await persistence.fetchLookupNamesForTesting(of: CategoryRecord.self)
        let orders = try await persistence.fetchAll()
        let categoriesByOrder = Dictionary(uniqueKeysWithValues: orders.map { order in
            (order.id, order.categories)
        })
        #expect(categories == ["衣著"])
        #expect(categoriesByOrder == ["LOOKUP-SOURCE": ["衣著"], "LOOKUP-TARGET": ["衣著"]])
    }

    /// 改名付款方式到既有項目時合併兩邊的旗標
    ///
    /// - Throws: 測試容器建立或改名寫入失敗時拋出錯誤
    @Test
    func paymentMethodRenameOntoExistingNameMergesFlags() async throws(any Error) {
        // Given
        let sourceFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let targetFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let sourceOrder = Self.makeLookupRenameOrder(id: "PAYMENT-SOURCE", paymentMethod: "匯款")
        let targetOrder = Self.makeLookupRenameOrder(id: "PAYMENT-TARGET", paymentMethod: "銀行匯款")
        let container = try Self.makeLookupRenameContainer(
            paymentMethods: [
                PaymentMethodRecord(
                    name: "匯款",
                    isCardless: sourceFlags.isCardless,
                    isBankTransfer: sourceFlags.isBankTransfer,
                    isCashOnDelivery: sourceFlags.isCashOnDelivery
                ),
                PaymentMethodRecord(
                    name: "銀行匯款",
                    isCardless: targetFlags.isCardless,
                    isBankTransfer: targetFlags.isBankTransfer,
                    isCashOnDelivery: targetFlags.isCashOnDelivery
                ),
            ],
            orders: [sourceOrder, targetOrder]
        )
        let persistence = OrderPersistence(modelContainer: container)

        // When
        try await persistence.applyPaymentMethodRename(from: "匯款", to: "銀行匯款")

        // Then
        let reader = PaymentMethodPersistence(modelContainer: container)
        let paymentMethods = try await reader.fetchAllInfos()
        let orders = try await persistence.fetchAll()
        let expectedFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        #expect(paymentMethods == [PaymentMethodInfo(name: "銀行匯款", flags: expectedFlags)])
        #expect(orders.first { $0.id == "PAYMENT-SOURCE" }?.paymentMethod == "銀行匯款")
    }

    /// 改名失敗後建立另一筆訂單不會存入尚未完成的主檔改名
    ///
    /// - Throws: 測試容器建立或持久化讀寫失敗時拋出錯誤
    @Test
    func failedRenameDoesNotPersistLookupWhenNextOrderIsCreated() async throws(any Error) {
        // Given
        let originalOrder = Self.makeLookupRenameOrder(
            id: "LOOKUP-FAILED-RENAME",
            categories: ["服飾"]
        )
        let container = try Self.makeLookupRenameContainer(
            categoryNames: ["服飾"],
            orders: [originalOrder]
        )
        let persistence = OrderPersistence(
            modelContainer: container,
            lookupRenameOrderFetcher: { _ in
                throw TestDependencies.makeUnderlyingError(message: "lookup rename fetch failed")
            }
        )

        // When
        var renameFailed = false
        do throws(PersistenceError) {
            try await persistence.applyCategoryRename(from: "服飾", to: "衣著")
        } catch {
            renameFailed = true
        }
        let unrelatedOrder = Self.makeLookupRenameOrder(id: "LOOKUP-UNRELATED")
        try await persistence.create(unrelatedOrder)

        // Then
        let reader = OrderPersistence(modelContainer: container)
        let categories = try await reader.fetchLookupNamesForTesting(of: CategoryRecord.self)
        let orders = try await reader.fetchAll()
        #expect(renameFailed)
        #expect(categories == ["服飾"])
        #expect(orders.contains { order in order.id == unrelatedOrder.id })
    }

    /// 另一個 context 更新旗標後，交易改名仍保留兩邊旗標
    ///
    /// - Throws: 測試容器建立或改名寫入失敗時拋出錯誤
    @Test
    func paymentMethodRenameUsesFlagsSavedByAnotherContext() async throws(any Error) {
        // Given
        let targetFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let newlySavedFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let container = try Self.makeLookupRenameContainer(
            paymentMethods: [
                PaymentMethodRecord(name: "匯款"),
                PaymentMethodRecord(
                    name: "銀行匯款",
                    isCardless: targetFlags.isCardless,
                    isBankTransfer: targetFlags.isBankTransfer,
                    isCashOnDelivery: targetFlags.isCashOnDelivery
                ),
            ],
            orders: [Self.makeLookupRenameOrder(id: "PAYMENT-STALE", paymentMethod: "匯款")]
        )
        let persistence = OrderPersistence(modelContainer: container)
        let flagsBeforeExternalWrite = try await persistence.fetchPaymentMethodInfosForTesting()
        let paymentMethodPersistence = PaymentMethodPersistence(modelContainer: container)
        try await paymentMethodPersistence.upsert(name: "匯款", flags: newlySavedFlags)

        // When
        try await persistence.applyPaymentMethodRename(from: "匯款", to: "銀行匯款")

        // Then
        let reader = PaymentMethodPersistence(modelContainer: container)
        let paymentMethods = try await reader.fetchAllInfos()
        let orders = try await persistence.fetchAll()
        let expectedFlags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        #expect(
            flagsBeforeExternalWrite.first {
                $0.name == "匯款"
            }?.currentFlags == PaymentMethodFlags.none
        )
        #expect(paymentMethods == [PaymentMethodInfo(name: "銀行匯款", flags: expectedFlags)])
        #expect(orders.first?.paymentMethod == "銀行匯款")
    }
}

// MARK: - Private Method

private extension OrderPersistenceTests {

    /// 建立預先寫入主檔與訂單的記憶體容器
    ///
    /// - Parameters:
    ///   - categoryNames: 預先寫入的商品類別名稱
    ///   - paymentMethods: 預先寫入的付款方式記錄
    ///   - orders: 預先寫入的訂單
    /// - Returns: 已儲存測試資料的容器
    /// - Throws: 建立容器或儲存樣本失敗時拋出錯誤
    static func makeLookupRenameContainer(
        categoryNames: [String] = [],
        paymentMethods: [PaymentMethodRecord] = [],
        orders: [LedgerOrder]
    ) throws(any Error) -> ModelContainer {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let modelContext = ModelContext(container)
        for name in categoryNames {
            modelContext.insert(CategoryRecord(name: name))
        }
        for paymentMethod in paymentMethods {
            modelContext.insert(paymentMethod)
        }
        for order in orders {
            modelContext.insert(OrderRecord(order: order))
        }
        try modelContext.save()
        return container
    }
}
