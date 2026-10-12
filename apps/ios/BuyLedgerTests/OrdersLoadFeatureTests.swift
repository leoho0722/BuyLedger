//
//  OrdersLoadFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 訂單與四種主檔載入結果的測試
@MainActor
struct OrdersLoadFeatureTests {

    /// 成功載入時替換訂單與四種主檔，不改動付款方式旗標
    @Test
    func loadRequested_讀取成功_更新共用訂單與四種主檔() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let method = PaymentMethodInfo(
            name: "orders.edit.label.bankTransfer",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let initial = Self.makeState()
        initial.$lookupCatalog.withLock {
            $0.orderSources = ["舊來源"]
            $0.categories = ["舊類別"]
            $0.reconciliationStatuses = ["舊狀態"]
        }
        let ordersReader = SharedReader(initial.$orders)
        let loadingReader = SharedReader(initial.$isLoading)
        let loadedReader = SharedReader(initial.$hasLoaded)
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = {
                [order]
            }
            $0.orderSourceService.fetchOrderSources = {
                ["IG"]
            }
            $0.categoryService.fetchCategories = {
                ["美妝"]
            }
            $0.paymentMethodService.fetchPaymentMethodInfos = {
                [method]
            }
            $0.reconciliationStatusService.fetchReconciliationStatuses = {
                ["待對帳"]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.loadResponse) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [order]
            }
            $0.$lookupCatalog.withLock {
                $0.orderSources = ["IG"]
                $0.categories = ["美妝"]
                $0.paymentMethods = [method]
                $0.reconciliationStatuses = ["待對帳"]
            }
        }
        await store.finish()
        #expect(ordersReader.wrappedValue == [order])
        #expect(loadingReader.wrappedValue == false)
        #expect(loadedReader.wrappedValue)
        #expect(store.state.errorMessage == nil)
    }

    /// 訂單讀取失敗時保留原有訂單，失敗的主檔維持原值，不標記為已載入並通知父層
    @Test
    func loadRequested_訂單讀取失敗_保留資料並委派錯誤() async {
        // Given
        let order = LedgerOrder.fixture(id: "existing")
        let initial = Self.makeState(orders: [order])
        initial.$lookupCatalog.withLock {
            $0.categories = ["既有類別"]
        }
        let failingFetch: OrderService.FetchOrders = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = failingFetch
            Self.suppressLookups(&$0)
            $0.orderSourceService.fetchOrderSources = {
                ["IG"]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.loadResponse) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
            $0.$lookupCatalog.withLock {
                $0.orderSources = ["IG"]
            }
        }
        await store.receive(\.delegate.loadFailed)
        await store.finish()
        #expect(store.state.orders == [order])
        #expect(store.state.lookupCatalog.orderSources == ["IG"])
        #expect(store.state.lookupCatalog.categories == ["既有類別"])
        #expect(store.state.isLoading == false)
        #expect(store.state.hasLoaded == false)
    }

    /// 主檔各自合併，成功的空清單取代原值，失敗的欄位保留原值
    @Test
    func loadRequested_部分主檔失敗_只套用成功欄位() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1")
        let initial = Self.makeState()
        initial.$lookupCatalog.withLock {
            $0.orderSources = ["舊來源"]
            $0.categories = ["既有類別"]
            $0.reconciliationStatuses = ["既有狀態"]
        }
        let store = TestStore(initialState: initial) {
            OrdersLoadFeature()
        } withDependencies: {
            Self.suppressLookups(&$0)
            $0.orderService.fetchOrders = {
                [order]
            }
            $0.orderSourceService.fetchOrderSources = {
                []
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.loadResponse) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [order]
            }
            $0.$lookupCatalog.withLock {
                $0.orderSources = []
            }
        }
        await store.finish()
        #expect(store.state.lookupCatalog.categories == ["既有類別"])
        #expect(store.state.lookupCatalog.reconciliationStatuses == ["既有狀態"])
        #expect(store.state.errorMessage == nil)
    }
}

// MARK: - Internal Method

extension OrdersLoadFeatureTests {

    /// 建立使用獨立記憶體儲存的載入狀態，主檔目錄與訂單不外溢到其他測試
    ///
    /// - Parameter orders: 初始訂單
    /// - Returns: 尚未開始讀取的載入狀態
    static func makeState(orders: [LedgerOrder] = []) -> OrdersLoadFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            let shared = Shared<[LedgerOrder]>(value: [])
            shared.withLock {
                $0 = orders
            }
            return OrdersLoadFeature.State(orders: shared)
        }
    }

    /// 讓四種主檔的讀取都失敗，主檔內容維持測試設定的原值
    ///
    /// - Parameter dependencies: 測試注入的依賴集合
    static func suppressLookups(_ dependencies: inout DependencyValues) {
        let sources: OrderSourceService.FetchOrderSources = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let categories: CategoryService.FetchCategories = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let methods: PaymentMethodService.FetchPaymentMethodInfos = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        let statuses: ReconciliationStatusService.FetchReconciliationStatuses = { () throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "lookup"))
        }
        dependencies.orderSourceService.fetchOrderSources = sources
        dependencies.categoryService.fetchCategories = categories
        dependencies.paymentMethodService.fetchPaymentMethodInfos = methods
        dependencies.reconciliationStatusService.fetchReconciliationStatuses = statuses
    }
}
