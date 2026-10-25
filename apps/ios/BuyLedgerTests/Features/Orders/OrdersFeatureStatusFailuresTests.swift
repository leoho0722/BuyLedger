//
//  OrdersFeatureStatusFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證訂單、收款與批次狀態寫入失敗後的資料復原
@MainActor
struct OrdersFeatureStatusFailuresTests {

    /// 驗證訂單狀態寫入失敗後，根功能要求重新載入，列表讀回磁碟上的原訂單並選取「O1」
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func rootRequest_訂單狀態寫入失敗後重新載入_讀回原訂單() async throws {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(
            id: "O1",
            categories: ["beauty"],
            status: .shipping
        )
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.orderStatusUpdated"
        )
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            try await service.fetchOrders().map(LedgerOrder.normalizingItemIdentifiers)
        }
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
        }

        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse)
        await store.receive(\.writes.delegate, .failed(.status))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }

        // When
        await store.send(.rootRequest(.load)) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.load.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [original]
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "O1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(initial.$orders)
            )
        }
        #expect(store.state.orders == [original], "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        await store.finish()
    }

    /// 驗證收款狀態寫入失敗後，根功能要求重新載入，列表讀回磁碟上的原訂單並選取「O1」
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func rootRequest_收款狀態寫入失敗後重新載入_讀回原訂單() async throws {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.receiptStatusUpdated"
        )
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            try await service.fetchOrders().map(LedgerOrder.normalizingItemIdentifiers)
        }
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
        }

        await store.send(.rootRequest(.receiptStatusChange(id: "O1", status: .received)))
        await store.receive(\.writes.receiptToggleRequested)
        await store.receive(\.writes.receiptResponse)
        await store.receive(\.writes.delegate, .failed(.receipt))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }

        // When
        await store.send(.rootRequest(.load)) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.load.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = [original]
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "O1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(initial.$orders)
            )
        }
        #expect(store.state.orders == [original], "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        await store.finish()
    }

    /// 驗證批次狀態寫入失敗後，根功能要求重新載入，列表讀回磁碟上的四筆原訂單並選取「O1」
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func rootRequest_批次狀態寫入失敗後重新載入_讀回原訂單() async throws {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "O1",
                status: .shipping,
                date: Date(timeIntervalSince1970: 4_000),
                categories: ["beauty"]
            ),
            LedgerOrder.fixture(
                id: "O2",
                status: .shipping,
                date: Date(timeIntervalSince1970: 3_000),
                categories: ["beauty"]
            ),
            LedgerOrder.fixture(
                id: "O3",
                status: .shipping,
                date: Date(timeIntervalSince1970: 2_000),
                categories: ["beauty"]
            ),
            LedgerOrder.fixture(
                id: "O4",
                status: .shipping,
                date: Date(timeIntervalSince1970: 1_000),
                categories: ["beauty"]
            ),
        ]
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(
            orders: orders
        )
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            try await service.fetchOrders().map(LedgerOrder.normalizingItemIdentifiers)
        }
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.batchStatusUpdate"
        )
        var state = OrdersFeature.State(orders: orders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.isSelecting = true
        state.list.selectedOrderIDs = Set(orders.map(\.id))

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrders = service.saveOrders
        }

        await store.send(.list(.view(.batchStatusChanged(.arrived)))) {
            $0.list.isSelecting = false
            $0.list.selectedOrderIDs = []
        }
        await store.receive(\.list.delegate.requested)
        await store.receive(\.writes.batchStatusChangeRequested)
        await store.receive(\.writes.batchStatusResponse)
        await store.receive(\.writes.delegate, .failed(.batchStatus))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }

        // When
        await store.send(.rootRequest(.load)) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.load.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = orders
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "O1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(state.$orders)
            )
        }
        #expect(store.state.orders == orders, "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        #expect(store.state.list.selectedOrderID == "O1")
        await store.finish()
    }
}
