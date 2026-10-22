//
//  OrdersFeatureTests+Photos.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 照片載入完成且修改過時儲存，連同新照片一起寫入並更新清單
    ///
    /// - Note: 照片已載入且修改過時應走帶照片的寫入；誤走不帶照片的 `saveOrder` 會因未覆寫而讓測試失敗
    @Test
    func presentation_修改既有訂單照片_儲存後更新訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])
        let photos = [Data([0x01]), Data([0x02])]

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.photos.photoLoadPhase = .loaded
        draft.photos.hasEditedPhotos = true
        draft.photos.draftPhotos = photos

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
            $0.orderService.saveOrderPersistingPhotos = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", categories: ["美妝"], photos: photos)

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

    /// 照片尚未載入完成時儲存，即使標記過修改也只更新文字欄位
    ///
    /// - Parameter phase: 照片目前的載入狀態
    /// - Note: 照片未載入完成時不應走帶照片的寫入；誤走 `saveOrderPersistingPhotos` 會因未覆寫而讓測試失敗
    @Test(arguments: [OrderEditPhotosFeature.State.PhotoLoadPhase.loading, .failed, .notLoaded])
    func presentation_照片尚未載入_保留原照片(phase: OrderEditPhotosFeature.State.PhotoLoadPhase) async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.photos.photoLoadPhase = phase
        draft.photos.hasEditedPhotos = true
        draft.photos.draftPhotos = [Data([0xBB])]
        draft.draft.customerName = "照片尚未載入就儲存"

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
            customer: LedgerCustomer(name: "照片尚未載入就儲存", initials: "TC", tier: .regular),
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
}
