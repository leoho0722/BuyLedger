//
//  OrderWritesFeatureTests+Create.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 原訂單仍存在與並行移除兩種情境，都依解析結果選擇更新或建立
    ///
    /// - Parameter isOriginalPresent: 原訂單是否仍在共用清單內
    @Test(arguments: [true, false])
    func saveRequested_原訂單存在或已移除_依解析意圖更新或建立(isOriginalPresent: Bool) async {
        // Given
        let initial = Self.makeState()
        if !isOriginalPresent {
            initial.$orders.withLock {
                $0 = [Self.other]
            }
        }
        let edit = Self.makeEdit()
        let expected = LedgerOrder.fixture(
            id: isOriginalPresent ? "O1" : "BL-DRAFT-00000000-0000-0000-0000-000000000001",
            customer: LedgerCustomer(
                name: "測試客戶",
                initials: isOriginalPresent ? "TC" : "測試",
                tier: isOriginalPresent ? .regular : .new
            ),
            status: .confirmed,
            categories: ["美妝"],
            notes: "已修改"
        )
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let record: @Sendable (LedgerOrder) -> Void = { order in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(order)
            }
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            if isOriginalPresent {
                $0.orderService.saveOrder = {
                    record($0)
                }
            } else {
                $0.orderService.createOrder = {
                    record($0)
                }
            }
        }

        // When
        await store.send(.saveRequested(edit))

        // Then
        await store.receive(\.saveResponse) {
            $0.$orders.withLock {
                $0 = [expected, Self.other]
            }
        }
        await store.receive(\.delegate, .saved(id: expected.id, isNewOrder: !isOriginalPresent))
        await store.finish()
        let expectedBeforeWrite = isOriginalPresent ? [Self.original, Self.other] : [Self.other]
        #expect(observedOrders.value == [expectedBeforeWrite])
        #expect(calls.value == [expected])
    }

    /// 新建列明確帶照片呼叫建立入口，成功才插入清單最前方
    @Test
    func saveRequested_新建含照片成功_建立後插入訂單() async {
        // Given
        let initial = Self.makeState()
        var edit = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        edit.draft.customerName = "新客戶"
        edit.draft.orderSource = "IG"
        edit.draft.categories = ["美妝"]
        edit.photos.draftPhotos = [Data([3, 4])]
        let expected = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000001",
            customer: LedgerCustomer(name: "新客戶", initials: "新客", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝"],
            paymentMethod: "",
            photos: [Data([3, 4])]
        )
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            $0.orderService.createOrder = { order in
                observedOrders.withValue {
                    $0.append(sharedOrders.wrappedValue)
                }
                calls.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.saveRequested(edit))

        // Then
        await store.receive(\.saveResponse) {
            $0.$orders.withLock {
                $0.insert(expected, at: 0)
            }
        }
        await store.receive(\.delegate, .saved(id: expected.id, isNewOrder: true))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [expected])
    }

    /// 新建撞號時不以更新入口覆寫，也不把失敗訂單加入共用清單
    @Test
    func saveRequested_新建撞號_不加入訂單並回報失敗() async {
        // Given
        let initial = Self.makeState()
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let failingCreate: OrderService.CreateOrder = { order throws(OrderPersistenceError) in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(order)
            }
            throw .identifierCollision(id: order.id)
        }
        let edit = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            $0.orderService.createOrder = failingCreate
        }

        // When
        await store.send(.saveRequested(edit))

        // Then
        await store.receive(\.saveResponse)
        await store.receive(\.delegate, .failed(.save))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value.count == 1)
        #expect(calls.value.first?.id == "BL-DRAFT-00000000-0000-0000-0000-000000000001")
        #expect(initial.orders == [Self.original, Self.other])
    }
}
