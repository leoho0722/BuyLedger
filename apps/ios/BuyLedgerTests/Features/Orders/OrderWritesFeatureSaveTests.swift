//
//  OrderWritesFeatureSaveTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderWritesFeature` 的單元測試，以 `TestStore` 逐步驗證編輯儲存依照片意圖寫入，失敗與目標已移除時不重新插入訂單
@MainActor
struct OrderWritesFeatureSaveTests {

    // MARK: - Properties

    /// 失敗情境下應維持不變的原訂單
    private static let original = OrderWritesFeatureTestSupport.original

    /// 不參與操作的另一筆訂單
    private static let other = OrderWritesFeatureTestSupport.other

    /// 驗證編輯儲存成功時，照片已載入且有修改才呼叫 `saveOrderPersistingPhotos`，否則呼叫 `saveOrder`，成功回應後目標訂單被替換為編輯結果
    ///
    /// - Parameter hasPhotoEdits: 是否完成照片載入並修改照片
    @Test(arguments: [false, true])
    func saveRequested_編輯成功_依照片意圖寫入後更新訂單(hasPhotoEdits: Bool) async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        var edit = OrderWritesFeatureTestSupport.makeEdit()
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

    /// 驗證一般寫入與照片寫入失敗時，共用清單保留原訂單，並回報儲存失敗
    ///
    /// - Parameter hasPhotoEdits: 是否使用照片寫入入口
    @Test(arguments: [false, true])
    func saveRequested_編輯失敗_保留資料並回報失敗(hasPhotoEdits: Bool) async {
        // Given
        let initial = OrderWritesFeatureTestSupport.makeState()
        var edit = OrderWritesFeatureTestSupport.makeEdit()
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

    /// 驗證編輯寫入成功的回應抵達時，目標訂單已不在共用清單中，回應不會把它重新插入，但仍送出儲存完成通知
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
