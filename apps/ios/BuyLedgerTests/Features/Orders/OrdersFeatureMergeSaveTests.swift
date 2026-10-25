//
//  OrdersFeatureMergeSaveTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證合併訂單的儲存、來源標記與照片寫入
@MainActor
struct OrdersFeatureMergeSaveTests {

    /// 驗證儲存合併草稿時，新增一筆合併訂單，並把兩筆來源訂單標成已合併
    ///
    /// - Throws: 找不到合併來源訂單時由 `#require` 丟出
    @Test
    func presentation_儲存合併草稿_新增訂單並標記來源() async throws {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        // 合併草稿沿用主訂單客戶的 `initials` 與 `tier`
        let expectedMergedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            chargedAmount: 17_480,
            orderSource: "IG",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            mergedSourceIDs: [primaryID, secondaryID]
        )
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.orderSource = "IG"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        state.presentation.destination = .edit(draft)

        let mergedOrders = LockIsolated<[LedgerOrder]>([])
        let consumedIDCalls = LockIsolated<[[LedgerOrder.ID]]>([])
        let primaryIndex = try #require(state.orders.firstIndex { $0.id == primaryID })
        let secondaryIndex = try #require(state.orders.firstIndex { $0.id == secondaryID })
        var expectedOrders = state.orders
        expectedOrders[primaryIndex] = OrdersFeatureTestSupport.withStatus(
            state.orders[primaryIndex],
            status: .merged
        )
        expectedOrders[secondaryIndex] = OrdersFeatureTestSupport.withStatus(
            state.orders[secondaryIndex],
            status: .merged
        )
        expectedOrders.insert(expectedMergedOrder, at: 0)
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.mergeOrders = { newOrder, consumedIDs in
                mergedOrders.withValue {
                    $0.append(newOrder)
                }
                consumedIDCalls.withValue {
                    $0.append(consumedIDs)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.delegate, .merged(id: expectedMergedOrder.id)) {
            $0.list.selectedOrderID = expectedMergedOrder.id
        }
        await store.receive(\.list.delegate.selectionChanged, expectedMergedOrder.id) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: expectedMergedOrder.id,
                orders: SharedReader(state.$orders)
            )
        }
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.mergeResponse)
        await store.finish()
        #expect(mergedOrders.value == [expectedMergedOrder])
        #expect(consumedIDCalls.value == [[primaryID, secondaryID]])
    }

    /// 驗證完成合併且保留照片時，新訂單帶著保留的照片寫入
    ///
    /// - Throws: 找不到合併來源訂單時由 `#require` 丟出
    @Test
    func presentation_完成合併且保留照片_明確寫入合併照片() async throws {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let keptPhotos = [Data([0x21]), Data([0x22]), Data([0x23])]
        // 合併草稿沿用主訂單客戶的 `initials` 與 `tier`
        let expectedMergedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            chargedAmount: 17_480,
            orderSource: "IG",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            photos: keptPhotos,
            mergedSourceIDs: [primaryID, secondaryID]
        )
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.orderSource = "IG"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        draft.photos.draftPhotos = keptPhotos
        state.presentation.destination = .edit(draft)

        let mergedOrders = LockIsolated<[LedgerOrder]>([])
        let primaryIndex = try #require(state.orders.firstIndex { $0.id == primaryID })
        let secondaryIndex = try #require(state.orders.firstIndex { $0.id == secondaryID })
        var expectedOrders = state.orders
        expectedOrders[primaryIndex] = OrdersFeatureTestSupport.withStatus(
            state.orders[primaryIndex],
            status: .merged
        )
        expectedOrders[secondaryIndex] = OrdersFeatureTestSupport.withStatus(
            state.orders[secondaryIndex],
            status: .merged
        )
        expectedOrders.insert(expectedMergedOrder, at: 0)
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.mergeOrders = { newOrder, _ in
                mergedOrders.withValue {
                    $0.append(newOrder)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.writes.delegate, .merged(id: expectedMergedOrder.id)) {
            $0.list.selectedOrderID = expectedMergedOrder.id
        }
        await store.receive(\.list.delegate.selectionChanged, expectedMergedOrder.id) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: expectedMergedOrder.id,
                orders: SharedReader(state.$orders)
            )
        }
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.mergeResponse)
        await store.finish()
        #expect(mergedOrders.value == [expectedMergedOrder])
    }

    /// 驗證合併草稿有預填內容時按下取消，先詢問是否捨棄，訂單清單不變
    @Test
    func presentation_合併草稿按下取消_詢問是否捨棄() async {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.mergeSourceIDs = ["BL-2604-018", "BL-2604-012"]
        draft.draft.customerName = "林書宇"
        state.presentation.destination = .edit(draft)
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.cancelTapped)))))) {
            $0.presentation.destination?.modify(\.edit) {
                $0.discardConfirmation = AlertState {
                    TextState("orders.list.label.discardChanges")
                } actions: {
                    ButtonState(role: .destructive, action: .discard) {
                        TextState("orders.list.label.discardChanges")
                    }
                    ButtonState(role: .cancel) {
                        TextState("orders.list.label.keepEditing")
                    }
                } message: {
                    TextState("orders.edit.message.orderHasUnsaved")
                }
            }
        }

        // Then
        #expect(store.state.presentation.destination?.edit?.discardConfirmation != nil)
        #expect(store.state.orders == LedgerOrder.sampleOrders)
    }
}
