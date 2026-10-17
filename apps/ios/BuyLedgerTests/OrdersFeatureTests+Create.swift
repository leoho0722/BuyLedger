//
//  OrdersFeatureTests+Create.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 新增含照片的訂單並儲存，新訂單帶著照片加入清單
    @Test
    func presentation_新增訂單含照片_儲存後加入訂單() async {
        // Given
        let photos = [Data([0xA1])]

        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新照片客戶"
        draft.draft.orderSource = "IG"
        draft.draft.categories = ["美妝"]
        draft.photos.draftPhotos = photos

        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let createdOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新照片客戶", initials: "新照", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝"],
            paymentMethod: "",
            photos: photos
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved) {
            $0.list.selectedOrderID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        }
        await store.receive(
            \.list.delegate.selectionChanged,
            "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        ) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
                orders: SharedReader($0.$orders)
            )
        }
        #expect(createdOrders.value == [expectedOrder])
    }

    /// 新增訂單儲存成功後，新訂單排到清單最前面並被選取
    ///
    /// - Note: 新訂單一律走建立操作；誤走 `saveOrder` 會因未覆寫而讓測試失敗
    @Test
    func presentation_新增訂單儲存成功_加入並選取新訂單() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.orderSource = "IG"
        draft.draft.categories = ["美妝"]

        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let createdOrders = LockIsolated<[LedgerOrder]>([])

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新客戶", initials: "新客", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝"],
            paymentMethod: ""
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder] + LedgerOrder.sampleOrders
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved) {
            $0.list.selectedOrderID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        }
        await store.receive(
            \.list.delegate.selectionChanged,
            "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        ) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
                orders: SharedReader($0.$orders)
            )
        }
        #expect(createdOrders.value == [expectedOrder])
    }

    /// 新增訂單寫入失敗時，清單不加入新訂單並顯示寫入失敗提示
    @Test
    func formSheetDismissed_新增操作失敗_不加入訂單() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.orderSource = "IG"
        draft.draft.categories = ["美妝"]

        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let expectedID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        let failingCreate: OrderService.CreateOrder = { _ throws(OrderError) in
            throw .identifierCollision(id: expectedID)
        }

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0.orderService.createOrder = failingCreate
        }

        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        // 通過必填驗證後關閉表單，與寫入結果無關
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate, .failed(.save))
        await store.receive(
            \.presentation.noticeRequested,
            .alert(Self.expectedWriteFailureAlert("orders.general.message.orderSavedTry"))
        ) {
            $0.presentation.queue.pendingNotice = .alert(
                Self.expectedWriteFailureAlert("orders.general.message.orderSavedTry")
            )
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = .alert(
                Self.expectedWriteFailureAlert("orders.general.message.orderSavedTry")
            )
        }

        // Then
        #expect(store.state.orders == LedgerOrder.sampleOrders)
    }
}
