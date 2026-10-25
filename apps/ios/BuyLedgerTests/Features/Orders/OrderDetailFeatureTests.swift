//
//  OrderDetailFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderDetailFeature` 的單元測試，涵蓋詳情內容、狀態選項與送出的操作請求
struct OrderDetailFeatureTests {

    /// 驗證一般訂單的可選狀態不含已合併，其餘狀態依既有順序排列
    @Test
    func selectableStatuses_一般訂單_排除已合併() {
        // Given
        let state = Self.makeState(status: .confirmed)

        // When
        let statuses = state.selectableStatuses

        // Then
        #expect(
            statuses == [
                .quoting,
                .confirmed,
                .purchased,
                .shipping,
                .partiallyArrived,
                .arrived,
                .delivered,
                .pickedUp,
                .cancelled,
            ]
        )
    }

    /// 驗證已合併訂單的可選狀態在既有順序後多出已合併，其餘與一般訂單相同
    @Test
    func selectableStatuses_已合併訂單_保留全部狀態() {
        // Given
        let state = Self.makeState(status: .merged)

        // When
        let statuses = state.selectableStatuses

        // Then
        #expect(
            statuses == [
                .quoting,
                .confirmed,
                .purchased,
                .shipping,
                .partiallyArrived,
                .arrived,
                .delivered,
                .pickedUp,
                .cancelled,
                .merged,
            ]
        )
    }

    /// 驗證已確認的訂單可合併，已取消與已合併的訂單不可合併
    ///
    /// - Parameter testCase: 訂單狀態與預期合併資格
    @Test(arguments: [
        MergeEligibilityCase(status: .confirmed, canBeMerged: true),
        MergeEligibilityCase(status: .cancelled, canBeMerged: false),
        MergeEligibilityCase(status: .merged, canBeMerged: false),
    ])
    func canMerge_不同訂單狀態_依規則提供資格(testCase: MergeEligibilityCase) {
        // Given
        let state = Self.makeState(status: testCase.status)

        // When
        let canMerge = state.canMerge

        // Then
        #expect(canMerge == testCase.canBeMerged)
    }

    /// 驗證貨到付款的訂單，詳情從共用資料取出七項成本，含三種手續費與三種運費，並帶出金額與色調
    @Test
    func costComponents_貨到付款_提供七項金額與色調() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [
                LedgerOrder.fixture(
                    id: "A",
                    date: TestDependencies.fixedNow,
                    itemCost: 100,
                    domesticShipping: 11,
                    internationalShipping: 22,
                    foreignDomesticShipping: 33,
                    cardFeeRate: Decimal(1) / 100,
                    platformFeeRate: Decimal(2) / 100,
                    paymentFeeRate: Decimal(3) / 100,
                    chargedAmount: 1_000,
                    isCashOnDelivery: true
                ),
            ]
        }
        let state = OrderDetailFeature.State(orderID: "A", orders: SharedReader(orders))

        // When
        let components = state.costComponents

        // Then
        #expect(
            components.map(\.title) == [
                "orders.detail.label.itemCost",
                "orders.detail.label.cardFee",
                "orders.detail.label.platformFee",
                "orders.detail.label.paymentProcessingFee",
                "orders.detail.label.localShipping",
                "orders.detail.label.internationalShipping",
                "orders.detail.label.foreignLocalShipping",
            ]
        )
        #expect(components.map(\.value) == [100, 10, 20, 30, 11, 22, 33])
        #expect(
            components.map(\.tone) == [.accent, .orange, .teal, .purple, .indigo, .pink, .yellow]
        )
    }

    /// 驗證共用訂單更新後，詳情的訂單狀態、合併資格與成本立即反映新值
    @Test
    func order_共用訂單更新_立即讀取新值() {
        // Given
        let orders = Shared(value: [LedgerOrder.fixture(id: "A", itemCost: 100)])
        let state = OrderDetailFeature.State(orderID: "A", orders: SharedReader(orders))

        // When
        orders.withLock {
            $0 = [LedgerOrder.fixture(id: "A", status: .cancelled, itemCost: 200)]
        }

        // Then
        #expect(state.order?.status == .cancelled)
        #expect(state.canMerge == false)
        #expect(state.costComponents.map(\.value) == [200])
    }

    /// 驗證找不到訂單時，訂單為 `nil`，狀態選項與成本為空，也無法合併
    @Test
    func order_找不到訂單_清空內容與選項() {
        // Given
        let state = OrderDetailFeature.State(orderID: "missing", orders: SharedReader(value: []))

        // When
        let order = state.order

        // Then
        #expect(order == nil)
        #expect(state.selectableStatuses.isEmpty)
        #expect(state.canMerge == false)
        #expect(state.costComponents.isEmpty)
    }

    /// 驗證選擇已到貨時，詳情只送出變更狀態的請求，訂單狀態本身不變
    @Test
    @MainActor
    func statusChanged_選擇已到貨_委派狀態請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.statusChanged(.arrived)))

        // Then
        await store.receive(\.delegate.requested, .changeStatus(id: "A", status: .arrived))
        #expect(store.state.order?.status == .confirmed)
    }

    /// 驗證點按編輯時，送出帶有目前訂單識別值的編輯請求
    @Test
    @MainActor
    func editTapped_點擊編輯_委派編輯請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.editTapped))

        // Then
        await store.receive(\.delegate.requested, .edit("A"))
    }

    /// 驗證點按合併時，送出帶有目前訂單識別值的合併請求
    @Test
    @MainActor
    func mergeTapped_點擊合併_委派合併請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.mergeTapped))

        // Then
        await store.receive(\.delegate.requested, .merge("A"))
    }

    /// 驗證點按刪除時，只送出刪除請求，訂單本身仍保留在共用資料中
    @Test
    @MainActor
    func deleteTapped_點擊刪除_委派刪除請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.deleteTapped))

        // Then
        await store.receive(\.delegate.requested, .delete("A"))
        #expect(store.state.orders.map(\.id) == ["A"])
    }
}

// MARK: - Nested Types

extension OrderDetailFeatureTests {

    /// 合併資格測試的單一案例，含訂單狀態與預期的合併資格
    struct MergeEligibilityCase: Sendable {

        /// 訂單目前狀態
        let status: OrderStatus

        /// 是否可以合併
        let canBeMerged: Bool
    }
}

// MARK: - Private Method

private extension OrderDetailFeatureTests {

    /// 建立以獨立共用資料顯示訂單 A 的詳情狀態
    ///
    /// - Parameter status: 訂單目前狀態
    /// - Returns: 顯示 A 的詳情狀態
    static func makeState(status: OrderStatus) -> OrderDetailFeature.State {
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [LedgerOrder.fixture(id: "A", status: status, date: TestDependencies.fixedNow)]
        }
        return OrderDetailFeature.State(orderID: "A", orders: SharedReader(orders))
    }

    /// 建立以已確認訂單 A 為初始狀態的詳情 TestStore，供詳情操作測試使用
    ///
    /// - Returns: 初始狀態為已確認訂單 A 的 TestStore
    @MainActor
    static func makeStore() -> TestStoreOf<OrderDetailFeature> {
        TestStore(initialState: makeState(status: .confirmed)) {
            OrderDetailFeature()
        }
    }
}
