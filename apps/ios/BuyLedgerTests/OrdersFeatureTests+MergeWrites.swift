//
//  OrdersFeatureTests+MergeWrites.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 合併儲存失敗時，訂單列表還原成合併前的內容，並跳出儲存失敗的提示
    @Test
    func formSheetDismissed_合併寫入失敗_還原來源並呈現失敗() async {
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
        let failingMerge: OrderService.MergeOrders = { _, _ in
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .storage(.saveFailed(underlying: error))
            }
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
            )
        }
        let store = TestStore(
            initialState: Self.makeMergeWriteState(orders: [original, other], edit: edit)
        ) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.orderService.mergeOrders = failingMerge
        }

        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped)))))) {
            $0.$orders.withLock {
                $0 = [original, other]
            }
        }

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
                orders: SharedReader($0.$orders)
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
        await store.receive(\.presentation.noticeRequested, Self.failureNotice("合併訂單儲存失敗，請稍後再試。")) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("合併訂單儲存失敗，請稍後再試。")
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = Self.failureNotice("合併訂單儲存失敗，請稍後再試。")
        }

        // Then
        #expect(store.state.orders == [original, other])
        #expect(store.state.presentation.destination?.edit == nil)
        #expect(store.state.presentation.destination?.alert != nil)
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 建立含指定訂單與合併表單的訂單分頁狀態，日期固定為測試用的值
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
