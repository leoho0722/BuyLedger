//
//  OrderMergeFeatureCandidateSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderMergeFeature` 的單元測試，涵蓋候選訂單的照片載入、挑選轉場與錯誤提示
@MainActor
struct OrderMergeFeatureCandidateSelectionTests {

    /// 驗證雙方照片合計不超過上限 5 張時跳過挑選，直接送出合併完成通知，主訂單照片排在前面
    ///
    /// - Note: 清單上的訂單不帶照片，照片依訂單編號另外讀取
    @Test
    func candidateTapped_合併照片未超過上限_直接送出完成委派() async {
        // Given
        let primaryPhotos = [Data([0x01]), Data([0x02])]
        let secondaryPhotos = [Data([0x03]), Data([0x04]), Data([0x05])]
        let expectedKept = [Data([0x01]), Data([0x02]), Data([0x03]), Data([0x04]), Data([0x05])]
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let store = TestStore(
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: [primary, secondary],
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
            )
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = {
                $0 == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.view(.candidateTapped("O2")))

        // Then
        await store.receive(\.candidatePhotosResponse.success)
        await store.receive { action in
            guard let completed = action[case: \.delegate.completed] else {
                return false
            }
            return completed.primary == primary
                && completed.secondary == secondary
                && completed.keptPhotos == expectedKept
        }
        #expect(store.state.step == .selectCandidate)
    }

    /// 驗證雙方照片合計超過 5 張時進入挑選步驟，合併照片主訂單在前，並預先勾選最前面 5 張
    @Test
    func candidateTapped_合併照片超過上限_進入挑選步驟() async {
        // Given
        let primaryPhotos = [Data([1]), Data([2]), Data([3]), Data([4])]
        let secondaryPhotos = [Data([5]), Data([6]), Data([7])]
        let expectedPhotos = [
            Data([1]),
            Data([2]),
            Data([3]),
            Data([4]),
            Data([5]),
            Data([6]),
            Data([7]),
        ]
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let store = TestStore(
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: [primary, secondary],
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
            )
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = {
                $0 == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.view(.candidateTapped("O2")))

        // Then
        await store.receive(\.candidatePhotosResponse.success) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = expectedPhotos
            $0.selectedPhotoIndices = [0, 1, 2, 3, 4]
            $0.step = .selectPhotos
        }
    }

    /// 驗證選定候選訂單時，主訂單與候選訂單的照片都依訂單編號分別讀取
    ///
    /// - Note: 兩筆訂單本身帶有與讀取結果不同的照片，證明合併用的是依編號讀取的照片
    @Test
    func candidateTapped_選定候選訂單_依編號讀取雙方照片() async {
        // Given
        let requestedIDs = LockIsolated<[LedgerOrder.ID]>([])
        let primaryPhotos = [Data([1]), Data([2]), Data([3])]
        let secondaryPhotos = [Data([4]), Data([5]), Data([6]), Data([7])]
        let expectedPhotos = [
            Data([1]),
            Data([2]),
            Data([3]),
            Data([4]),
            Data([5]),
            Data([6]),
            Data([7]),
        ]
        let primary = OrderMergeFeatureTestSupport.makeOrder(
            id: "O1",
            status: .shipping,
            photos: [Data([0xA1])]
        )
        let secondary = OrderMergeFeatureTestSupport.makeOrder(
            id: "O2",
            status: .purchased,
            photos: [Data([0xB1])]
        )
        let store = TestStore(
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: [primary, secondary],
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
            )
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = { id in
                requestedIDs.withValue {
                    $0.append(id)
                }
                return id == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.view(.candidateTapped("O2")))

        // Then
        await store.receive(\.candidatePhotosResponse.success) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = expectedPhotos
            $0.selectedPhotoIndices = [0, 1, 2, 3, 4]
            $0.step = .selectPhotos
        }
        #expect(requestedIDs.value.sorted() == ["O1", "O2"])
    }

    /// 驗證候選訂單的照片讀取失敗時跳出錯誤提示，並停留在候選選擇步驟，可重新選取重試
    @Test
    func candidateTapped_載入照片失敗_顯示通知並停留候選步驟() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let failingFetchPhotos: OrderService.FetchOrderPhotos = { id throws(PersistenceError) in
            guard id != "O2" else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "photo load failed")
                )
            }
            return []
        }
        let store = TestStore(
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: [primary, secondary],
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
            )
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = failingFetchPhotos
        }

        // When
        await store.send(.view(.candidateTapped("O2")))

        // Then
        await store.receive(\.candidatePhotosResponse.failure) {
            $0.photoLoadFailureAlert = AlertState {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("orders.merge.message.orderPhotosLoaded")
            }
        }
        #expect(store.state.step == .selectCandidate, "載入失敗後仍可重新選取候選訂單重試")
    }
}
