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

/// 驗證訂單詳情的內容、狀態選項與交給容器的操作請求
@MainActor
struct OrderDetailFeatureTests {

    /// 一般訂單排除已合併，保留其餘狀態的原有順序
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

    /// 已合併訂單保留已合併選項
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

    /// 取消與已合併不能合併，一般訂單仍可合併
    ///
    /// - Parameters:
    ///   - status: 訂單目前狀態
    ///   - canBeMerged: 預期的合併資格
    @Test(arguments: [
        (OrderStatus.confirmed, true),
        (OrderStatus.cancelled, false),
        (OrderStatus.merged, false),
    ])
    func canMerge_不同訂單狀態_依規則提供資格(status: OrderStatus, canBeMerged: Bool) {
        // Given
        let state = Self.makeState(status: status)

        // When
        let canMerge = state.canMerge

        // Then
        #expect(canMerge == canBeMerged)
    }

    /// 詳情從共用訂單取出商品、三種手續費與貨到付款運費
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

    /// 共用資料更新後，詳情訂單與成本跟著更新
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

    /// 訂單不存在時不提供可操作的內容
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

    /// 狀態選單只送請求，不自行變更訂單
    @Test
    func statusChanged_選擇已到貨_委派狀態請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.statusChanged(.arrived)))

        // Then
        await store.receive(\.delegate.requested, .changeStatus(id: "A", status: .arrived))
        #expect(store.state.order?.status == .confirmed)
    }

    /// 編輯選單將目前訂單識別值交給容器
    @Test
    func editTapped_點擊編輯_委派編輯請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.editTapped))

        // Then
        await store.receive(\.delegate.requested, .edit("A"))
    }

    /// 合併選單將目前訂單識別值交給容器
    @Test
    func mergeTapped_點擊合併_委派合併請求() async {
        // Given
        let store = Self.makeStore()

        // When
        await store.send(.view(.mergeTapped))

        // Then
        await store.receive(\.delegate.requested, .merge("A"))
    }

    /// 刪除選單只請容器確認，不自行刪除訂單
    @Test
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

    /// 建立可接受詳情操作的測試容器
    ///
    /// - Returns: 顯示已確認訂單 A 的 `TestStore`
    static func makeStore() -> TestStoreOf<OrderDetailFeature> {
        TestStore(initialState: makeState(status: .confirmed)) {
            OrderDetailFeature()
        }
    }
}
