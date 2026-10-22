//
//  OrderWritesFeatureTests+Save.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 照片載入完成且有編輯才使用照片寫入入口，成功後替換共用訂單
    ///
    /// - Parameter hasPhotoEdits: 是否完成照片載入並修改照片
    @Test(arguments: [false, true])
    func saveRequested_編輯成功_依照片意圖寫入後更新訂單(hasPhotoEdits: Bool) async {
        // Given
        let initial = Self.makeState()
        var edit = Self.makeEdit()
        edit.photos.photoLoadPhase = .loaded
        edit.photos.hasEditedPhotos = hasPhotoEdits
        edit.photos.draftPhotos = [Data([1, 2])]
        let expected = LedgerOrder.fixture(
            id: "O1",
            status: .confirmed,
            categories: ["美妝"],
            notes: "已修改",
            photos: hasPhotoEdits ? [Data([1, 2])] : []
        )
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let save: OrderService.SaveOrder = { order in
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
            if hasPhotoEdits {
                $0.orderService.saveOrderPersistingPhotos = save
            } else {
                $0.orderService.saveOrder = save
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
        await store.receive(\.delegate, .saved(id: "O1", isNewOrder: false))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value == [expected])
        #expect(initial.orders == [expected, Self.other])
    }

    /// 一般與照片寫入失敗都保留原訂單，並交給容器呈現失敗
    ///
    /// - Parameter hasPhotoEdits: 是否使用照片寫入入口
    @Test(arguments: [false, true])
    func saveRequested_編輯失敗_保留資料並回報失敗(hasPhotoEdits: Bool) async {
        // Given
        let initial = Self.makeState()
        var edit = Self.makeEdit()
        edit.photos.photoLoadPhase = .loaded
        edit.photos.hasEditedPhotos = hasPhotoEdits
        edit.photos.draftPhotos = [Data([1, 2])]
        let sharedOrders = initial.$orders
        let observedOrders = LockIsolated<[[LedgerOrder]]>([])
        let calls = LockIsolated<[LedgerOrder]>([])
        let failingSave: OrderService.SaveOrder = { order throws(PersistenceError) in
            observedOrders.withValue {
                $0.append(sharedOrders.wrappedValue)
            }
            calls.withValue {
                $0.append(order)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "save"))
        }
        let store = TestStore(initialState: initial) {
            OrderWritesFeature()
        } withDependencies: {
            if hasPhotoEdits {
                $0.orderService.saveOrderPersistingPhotos = failingSave
            } else {
                $0.orderService.saveOrder = failingSave
            }
        }

        // When
        await store.send(.saveRequested(edit))

        // Then
        await store.receive(\.saveResponse)
        await store.receive(\.delegate, .failed(.save))
        await store.finish()
        #expect(observedOrders.value == [[Self.original, Self.other]])
        #expect(calls.value.count == 1)
        #expect(calls.value.first?.id == "O1")
        #expect(calls.value.first?.notes == "已修改")
        #expect(initial.orders == [Self.original, Self.other])
    }

    /// 編輯回應抵達時原訂單已移除，不因舊回應重新加入資料
    @Test
    func saveResponse_更新目標已移除_不重新插入訂單() async {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [])
        let store = TestStore(initialState: OrderWritesFeature.State(orders: orders)) {
            OrderWritesFeature()
        }
        let result = OrderDraft.WriteResult(
            order: Self.original,
            isNewOrder: false,
            shouldWritePhotos: false
        )

        // When
        await store.send(.saveResponse(.success(result)))

        // Then
        await store.receive(\.delegate, .saved(id: "O1", isNewOrder: false))
        await store.finish()
        #expect(store.state.orders.isEmpty)
    }
}
