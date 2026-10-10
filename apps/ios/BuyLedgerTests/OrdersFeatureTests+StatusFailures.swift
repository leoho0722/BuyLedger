//
//  OrdersFeatureTests+StatusFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 訂單狀態寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func loadRequested_訂單狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = Self.makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let writeFailureAlert = Self.expectedWriteFailureAlert("訂單狀態更新失敗，請稍後再試。")
        let fetchOrders: OrderService.FetchOrders = {
            let orders = try await service.fetchOrders()
            reloadedOrders.setValue(orders)
            return orders
        }
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.list(.delegate(.requested(.changeStatus(id: "O1", status: .arrived)))))
        await store.receive(\.writes.statusChangeRequested)
        await store.receive(\.writes.statusResponse)
        await store.receive(\.writes.delegate, .failed(.status))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }

        // When
        await store.send(.loadRequested) {
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
                $0 = reloadedOrders.value
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "O1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader($0.$orders)
            )
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == [original],
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 收款狀態寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func loadRequested_收款狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = Self.makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let writeFailureAlert = Self.expectedWriteFailureAlert("收款狀態更新失敗，請稍後再試。")
        let fetchOrders: OrderService.FetchOrders = {
            let orders = try await service.fetchOrders()
            reloadedOrders.setValue(orders)
            return orders
        }
        var initial = OrdersFeature.State(orders: [original])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.receiptStatusChangeRequested(id: "O1", status: .received))
        await store.receive(\.writes.receiptToggleRequested)
        await store.receive(\.writes.receiptResponse)
        await store.receive(\.writes.delegate, .failed(.receipt))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.destination = .alert(writeFailureAlert)
        }

        // When
        await store.send(.loadRequested) {
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
                $0 = reloadedOrders.value
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "O1"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader($0.$orders)
            )
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == [original],
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 批次狀態寫入失敗後重新讀取資料庫，讀回的仍是原本的四筆訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤；重新載入後沒有選取訂單時由 `#require` 丟出
    @Test
    func loadRequested_批次狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let orders = [
            Self.makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            Self.makeOrder(id: "O2", categories: ["beauty"], status: .shipping),
            Self.makeOrder(id: "O3", categories: ["beauty"], status: .shipping),
            Self.makeOrder(id: "O4", categories: ["beauty"], status: .shipping),
        ]
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(orders: orders)
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = {
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        let writeFailureAlert = Self.expectedWriteFailureAlert("批次更新狀態失敗，請稍後再試。")
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
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrders = service.saveOrders
            Self.suppressOrderLookupEffects(&$0)
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
        await store.send(.loadRequested) {
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
                $0 = reloadedOrders.value
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = reloadedOrders.value.first?.id
            // 讀回順序依日期由新到舊，同日期時未定義，右欄跟隨讀回的第一筆
            if let firstID = reloadedOrders.value.first?.id {
                $0.detail.regularDetail = OrderDetailFeature.State(
                    orderID: firstID,
                    orders: SharedReader($0.$orders)
                )
            }
        }
        let reloadedByID = store.state.orders
            .map(LedgerOrder.normalizingItemIdentifiers)
            .sorted { left, right in
                left.id < right.id
            }
        #expect(reloadedByID == orders, "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        let selectedOrderID = try #require(store.state.list.selectedOrderID)
        #expect(Set(orders.map(\.id)).contains(selectedOrderID))
        await store.finish()
    }
}
