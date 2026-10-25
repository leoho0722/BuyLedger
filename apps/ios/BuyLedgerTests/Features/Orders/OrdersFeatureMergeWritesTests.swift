//
//  OrdersFeatureMergeWritesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Clocks
import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證合併寫入失敗後的來源資料與通知
@MainActor
struct OrdersFeatureMergeWritesTests {

    /// 驗證編輯表單儲存合併寫入失敗時，訂單列表還原成合併前的 A、B 兩筆，失敗提示暫存在 `pendingNotice`
    @Test
    func presentation_編輯表單儲存合併寫入失敗_還原來源並暫存失敗通知() async {
        // Given
        let original = LedgerOrder.fixture(id: "A", categories: ["美妝"])
        let other = LedgerOrder.fixture(id: "B", status: .shipping, categories: ["食品"])
        var edit = OrderEditFeature.State(id: UUID(2), currentDate: TestDependencies.fixedNow)
        edit.draft.customerName = "測試客戶"
        edit.draft.orderSource = "IG"
        edit.draft.categories = ["美妝", "食品"]
        edit.mergeSourceIDs = ["A", "B"]
        let expected = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝", "食品"],
            paymentMethod: "",
            mergedSourceIDs: ["A", "B"]
        )
        let sourceA = LedgerOrder.fixture(id: "A", status: .merged, categories: ["美妝"])
        let sourceB = LedgerOrder.fixture(id: "B", status: .merged, categories: ["食品"])
        let clock = TestClock()
        let failingMerge: OrderService.MergeOrders = { _, _ throws(OrderError) in
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .storage(.saveFailed(underlying: error))
            }
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
            )
        }
        let initial = Self.makeMergeWriteState(orders: [original, other], edit: edit)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
            $0.orderService.mergeOrders = failingMerge
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expected, sourceA, sourceB]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.delegate, .merged(id: expected.id)) {
            $0.list.selectedOrderID = expected.id
        }
        await store.receive(\.list.delegate.selectionChanged, expected.id) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: expected.id,
                orders: SharedReader(initial.$orders)
            )
        }
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.writes.mergeResponse) {
            $0.$orders.withLock {
                $0 = [original, other]
            }
        }
        await store.receive(\.writes.delegate, .failed(.merge))
        await store.receive(
            \.presentation.noticeRequested,
            OrdersFeatureTestSupport.failureNotice("orders.general.message.mergedOrderSaved")
        ) {
            $0.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice(
                "orders.general.message.mergedOrderSaved"
            )
        }
        #expect(store.state.orders == [original, other])
        await store.finish()
    }

    /// 驗證合併失敗的提示已暫存、表單關好時，提示改為目前呈現的 `destination`，`pendingNotice` 清空
    @Test
    func formSheetDismissed_合併失敗通知已暫存_關好表單後呈現失敗提示() async {
        // Given
        let original = LedgerOrder.fixture(id: "A", categories: ["美妝"])
        let other = LedgerOrder.fixture(id: "B", status: .shipping, categories: ["食品"])
        let notice = OrdersFeatureTestSupport.failureNotice(
            "orders.general.message.mergedOrderSaved"
        )
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.$orders.withLock {
            $0 = [original, other]
        }
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = notice
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = notice
        }

        // Then
        #expect(store.state.orders == [original, other])
        #expect(store.state.presentation.destination == notice)
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrdersFeatureMergeWritesTests {

    /// 建立訂單分頁狀態，列表放入指定訂單，並把指定的合併表單設為 `destination`，日期固定為 `TestDependencies.fixedNow`
    ///
    /// - Parameters:
    ///   - orders: 合併前的來源訂單
    ///   - edit: 要儲存的合併表單
    /// - Returns: 含指定訂單與合併表單的訂單分頁狀態
    static func makeMergeWriteState(
        orders: [LedgerOrder],
        edit: OrderEditFeature.State
    ) -> OrdersFeature.State {
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.$orders.withLock {
            $0 = orders
        }
        state.presentation.destination = .edit(edit)
        return state
    }
}
