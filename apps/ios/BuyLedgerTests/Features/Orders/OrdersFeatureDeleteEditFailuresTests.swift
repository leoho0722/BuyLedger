//
//  OrdersFeatureDeleteEditFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 搭配磁碟資料庫，逐步驗證刪除與編輯寫入失敗後的資料復原
@MainActor
struct OrdersFeatureDeleteEditFailuresTests {

    /// 驗證刪除寫入失敗並顯示提示後重新載入，從磁碟資料庫讀回的仍是原訂單
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤
    @Test
    func rootRequest_刪除寫入失敗後重新載入_讀回原訂單() async throws {
        // Given
        let original = OrdersFeatureTestSupport.makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(orders: [
            original,
        ])
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            try await service.fetchOrders().map(LedgerOrder.normalizingItemIdentifiers)
        }
        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .alert(
            OrdersFeatureTestSupport.expectedDeletionConfirmation(
                orderID: original.id,
                customerName: original.customer.name
            )
        )
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.orderDeletedTry"
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.removeOrder = service.removeOrder
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
            $0.list.selectedOrderID = original.id
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(state.$orders)
            )
        }
        #expect(store.state.orders == [original], "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        await store.finish()
    }

    /// 驗證編輯儲存失敗並顯示提示後重新載入，從磁碟資料庫讀回的仍是原訂單，未儲存的改名不會出現
    ///
    /// - Throws: 建立測試用的磁碟資料庫失敗時丟出檔案系統或 SwiftData 底層錯誤；範例資料找不到該訂單時由 `#require` 丟出
    @Test
    func rootRequest_編輯儲存失敗後重新載入_讀回原訂單() async throws {
        // Given
        let originalID = "BL-2604-018"
        let original = try #require(LedgerOrder.sampleOrders.first { $0.id == originalID })
        let (service, directoryURL) = try OrderServiceTestSupport.makeSaveFailingService(
            orders: LedgerOrder.sampleOrders
        )
        defer {
            BuyLedgerDatabaseTestSupport.removeTemporaryDirectory(at: directoryURL)
        }
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            try await service.fetchOrders().map(LedgerOrder.normalizingItemIdentifiers)
        }
        let persistedOrders = LedgerOrder.sampleOrders.map(LedgerOrder.normalizingItemIdentifiers)
        let writeFailureAlert = OrdersFeatureTestSupport.expectedWriteFailureAlert(
            "orders.general.message.orderSavedTry"
        )

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
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
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
                $0 = persistedOrders
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = originalID
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-2604-018",
                orders: SharedReader(state.$orders)
            )
        }
        #expect(store.state.orders == persistedOrders, "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        await store.finish()
    }
}
