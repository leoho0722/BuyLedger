//
//  OrdersFeatureTests+SaveFailureTiming.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Clocks
import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 儲存失敗在表單關閉回呼前到達時先暫存，關閉回呼後才呈現通知
    @Test
    func formSheetDismissed_儲存失敗先於關閉回呼到達_關閉後才呈現通知() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: Self.makeSaveTimingState()) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            $0.continuousClock = clock
            $0.orderService.createOrder = Self.makeFailingCreateOrder(clock)
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, Self.failureNotice("orders.general.message.orderSavedTry")) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("orders.general.message.orderSavedTry")
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = Self.failureNotice("orders.general.message.orderSavedTry")
        }

        // Then
        #expect(store.state.orders == [])
        #expect(store.state.presentation.destination == Self.failureNotice("orders.general.message.orderSavedTry"))
        #expect(store.state.presentation.queue == OrdersPresentationQueue())
        await store.finish()
    }

    /// 儲存失敗在表單關閉回呼後到達時，到達當下直接呈現通知
    @Test
    func formSheetDismissed_儲存失敗在關閉回呼後到達_到達時直接呈現() async {
        // Given
        let clock = TestClock()
        let store = TestStore(initialState: Self.makeSaveTimingState()) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            $0.continuousClock = clock
            $0.orderService.createOrder = Self.makeFailingCreateOrder(clock)
        }
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
        }

        // Then
        await clock.advance(by: .seconds(1))
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.failed)
        await store.receive(\.presentation.noticeRequested, Self.failureNotice("orders.general.message.orderSavedTry")) {
            $0.presentation.destination = Self.failureNotice("orders.general.message.orderSavedTry")
        }
        #expect(store.state.orders == [])
        #expect(store.state.presentation.destination == Self.failureNotice("orders.general.message.orderSavedTry"))
        #expect(store.state.presentation.queue == OrdersPresentationQueue())
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 建立已開著編輯表單的訂單分頁狀態，表單已填入客戶、來源與類別
    ///
    /// - Returns: 編輯表單開啟中的訂單分頁狀態
    static func makeSaveTimingState() -> OrdersFeature.State {
        var edit = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        edit.draft.customerName = "測試客戶"
        edit.draft.orderSource = "IG"
        edit.draft.categories = ["美妝"]
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = .edit(edit)
        return initial
    }

    /// 建立寫入替身，等時鐘前進一秒後才丟出儲存失敗，讓失敗晚於表單關閉動畫
    ///
    /// - Parameter clock: 控制延遲的時鐘
    /// - Returns: 一秒後丟出儲存失敗的建立訂單替身
    static func makeFailingCreateOrder(
        _ clock: TestClock<Swift.Duration>
    ) -> OrderService.CreateOrder {
        let failingCreate: OrderService.CreateOrder = { _ throws(OrderPersistenceError) in
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .storage(.saveFailed(underlying: error))
            }
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
            )
        }
        return failingCreate
    }
}
