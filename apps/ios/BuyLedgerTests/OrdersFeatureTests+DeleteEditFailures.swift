//
//  OrdersFeatureTests+DeleteEditFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 刪除寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func loadRequested_刪除寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = Self.makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .alert(
            Self.expectedDeletionConfirmation(
                orderID: original.id,
                customerName: original.customer.name
            )
        )
        let writeFailureAlert = Self.expectedWriteFailureAlert("orders.general.message.orderDeletedTry")

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.removeOrder = service.removeOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        // 選擇 alert 按鈕後 TCA 會自動清空該次呈現
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("O1")))))) {
            $0.presentation.destination = nil
        }
        await store.receive(\.presentation.delegate.deleteConfirmed, "O1")
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse)
        await store.receive(\.writes.delegate, .failed(.delete))
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
            $0.list.selectedOrderID = original.id
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

    /// 編輯儲存失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤；範例資料找不到該訂單時由 `#require` 丟出
    @Test
    func loadRequested_編輯儲存失敗後_讀回原訂單() async throws {
        // Given
        let originalID = "BL-2604-018"
        let original = try #require(LedgerOrder.sampleOrders.first { $0.id == originalID })
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(
            orders: LedgerOrder.sampleOrders
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        let persistedOrders = LedgerOrder.sampleOrders.map(LedgerOrder.normalizingItemIdentifiers)
        let writeFailureAlert = Self.expectedWriteFailureAlert("orders.general.message.orderSavedTry")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "改名嘗試"

        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        // 通過必填驗證後關閉表單，與寫入結果無關
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate, .failed(.save))
        await store.receive(\.presentation.noticeRequested, .alert(writeFailureAlert)) {
            $0.presentation.queue.pendingNotice = .alert(writeFailureAlert)
        }
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
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
            $0.list.selectedOrderID = originalID
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-2604-018",
                orders: SharedReader($0.$orders)
            )
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == persistedOrders,
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }
}
