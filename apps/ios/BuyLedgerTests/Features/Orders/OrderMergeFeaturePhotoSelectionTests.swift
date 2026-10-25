//
//  OrderMergeFeaturePhotoSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderMergeFeature` 的單元測試，涵蓋照片挑選步驟的選取上限、返回候選與完成
@MainActor
struct OrderMergeFeaturePhotoSelectionTests {

    /// 驗證從照片挑選步驟返回時回到候選選擇，已選副訂單、合併照片與勾選位置都被清空
    @Test
    func backToCandidatesTapped_返回候選步驟_清除照片暫存() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) {
            OrderMergeFeature()
        }

        // When
        await store.send(.view(.backToCandidatesTapped)) {
            $0.step = .selectCandidate
            $0.selectedSecondary = nil
            $0.combinedPhotos = []
            $0.selectedPhotoIndices = []
        }

        // Then
        #expect(store.state.step == .selectCandidate)
        #expect(store.state.selectedSecondary == nil)
        #expect(store.state.combinedPhotos.isEmpty)
        #expect(store.state.selectedPhotoIndices.isEmpty)
    }

    /// 驗證已勾滿 5 張上限時，再勾選其他照片不生效，勾選位置維持不變
    @Test
    func photoToggled_已達保留照片上限_忽略新增選取() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [1, 2, 3, 4, 6]
        )
        let store = TestStore(initialState: initialState) {
            OrderMergeFeature()
        }

        // When
        await store.send(.view(.photoToggled(5)))

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4, 6])
    }

    /// 驗證取消勾選已勾選的照片時，該位置從勾選清單移除，其餘位置保留
    @Test
    func photoToggled_已勾選照片_取消勾選() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) {
            OrderMergeFeature()
        }

        // When
        await store.send(.view(.photoToggled(0))) {
            $0.selectedPhotoIndices = [1, 2, 3, 4]
        }

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4])
    }

    /// 驗證未達 5 張上限時勾選照片，該位置加入勾選清單
    @Test
    func photoToggled_未達上限_加入勾選() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) {
            OrderMergeFeature()
        }

        // When
        await store.send(.view(.photoToggled(6))) {
            $0.selectedPhotoIndices = [1, 2, 3, 4, 6]
        }

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4, 6])
    }

    /// 驗證按下繼續時，勾選的照片依原本位置排序後，隨合併完成通知一併送出
    @Test
    func photoStepConfirmTapped_確認保留照片_依索引順序送出委派() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let secondary = OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased)
        let expectedKept = [Data([1]), Data([3]), Data([4]), Data([6]), Data([7])]
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 2, 3, 5, 6]
        )
        let store = TestStore(initialState: initialState) {
            OrderMergeFeature()
        }

        // When
        await store.send(.view(.photoStepConfirmTapped))

        // Then
        await store.receive { action in
            guard let completed = action[case: \.delegate.completed] else {
                return false
            }
            return completed.primary == primary
                && completed.secondary == secondary
                && completed.keptPhotos == expectedKept
        }
    }
}

// MARK: - Private Method

private extension OrderMergeFeaturePhotoSelectionTests {

    /// 建立停在照片挑選步驟的合併流程狀態，副訂單已選定，合併照片依序為位元組 1 到 7 的資料
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 已選定的副訂單
    ///   - selectedPhotoIndices: 目前勾選的照片位置
    /// - Returns: 照片挑選步驟的狀態
    static func makePhotoStepState(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        selectedPhotoIndices: Set<Int>
    ) -> OrderMergeFeature.State {
        var state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(
                primary: primary,
                orders: [primary, secondary],
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
            )
        }
        state.step = .selectPhotos
        state.selectedSecondary = secondary
        state.combinedPhotos = (1...7).map {
            Data([UInt8($0)])
        }
        state.selectedPhotoIndices = selectedPhotoIndices
        return state
    }
}
