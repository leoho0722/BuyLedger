//
//  OrdersFeatureTests+EditAmounts.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 修改訂單狀態、幣別與實收金額後儲存，三個欄位都寫回清單
    @Test
    func presentation_更新狀態幣別與金額_儲存後反映訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.status = .delivered
        draft.draft.currency = .jpy
        draft.draft.chargedAmount = 9_876

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            status: .delivered,
            currency: .jpy,
            chargedAmount: 9_876,
            categories: ["美妝"]
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
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 修改成本與手續費欄位後儲存，各欄位照輸入值寫回清單
    @Test
    func presentation_更新成本明細欄位_儲存後反映訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.itemCost = 5_000
        draft.draft.domesticShipping = 100
        draft.draft.internationalShipping = 250
        draft.draft.cardFeeRate = 0.025
        draft.draft.platformFeeRate = 0.04

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            itemCost: 5_000,
            domesticShipping: 100,
            internationalShipping: 250,
            cardFeeRate: 0.025,
            platformFeeRate: 0.04,
            categories: ["美妝"]
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
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 手續費率輸入小於 0 或大於 1 時，儲存前分別調成 0 與 1
    @Test
    func presentation_費率超出零至一範圍_夾限後儲存() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "order-1",
            cardFeeRate: 0.02,
            platformFeeRate: 0.03,
            categories: ["美妝"]
        )

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.cardFeeRate = -0.5
        draft.draft.platformFeeRate = 5

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            platformFeeRate: 1,
            categories: ["美妝"]
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
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 實收金額輸入負數時，儲存前調成 0
    @Test
    func presentation_實收金額輸入負值_夾限為零後儲存() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", chargedAmount: 1_000, categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.chargedAmount = -500

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

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
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }
}
