//
//  OrdersBatchOperationsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 直接測試批次狀態操作
struct OrdersBatchOperationsTests {

    /// 批次工具列保留所有既有狀態的順序，並排除已合併
    @Test
    func targetStatuses_批次狀態清單_保留順序並排除已合併() {
        // Given
        let expectedStatuses: [OrderStatus] = [
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

        // When
        let statuses = OrdersBatchOperations.targetStatuses()

        // Then
        #expect(statuses == expectedStatuses)
    }

    /// 驗證一般模式時進入多選
    @Test
    func selectionModeToggled_一般模式_進入多選() {
        // Given
        var state = OrderListFeatureTests.makeState()

        // When
        OrdersBatchOperations.selectionModeToggled(state: &state)

        // Then
        #expect(state.isSelecting == true)
    }

    /// 驗證多選模式時退出並清空選取
    @Test
    func selectionModeToggled_多選模式_退出並清空選取() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.isSelecting = true
        state.selectedOrderIDs = ["A", "B"]

        // When
        OrdersBatchOperations.selectionModeToggled(state: &state)

        // Then
        #expect(state.isSelecting == false)
        #expect(state.selectedOrderIDs.isEmpty)
    }

    /// 驗證未勾選的訂單點選後被勾選
    @Test
    func orderSelectionToggled_未勾選的訂單_勾選該訂單() {
        // Given
        var state = OrderListFeatureTests.makeState()

        // When
        OrdersBatchOperations.orderSelectionToggled("A", state: &state)

        // Then
        #expect(state.selectedOrderIDs == ["A"])
    }

    /// 驗證已勾選的訂單再點一次時取消勾選
    @Test
    func orderSelectionToggled_已勾選的訂單_取消勾選() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedOrderIDs = ["A"]

        // When
        OrdersBatchOperations.orderSelectionToggled("A", state: &state)

        // Then
        #expect(state.selectedOrderIDs.isEmpty)
    }

    /// 驗證清單有篩選時只選相符訂單
    @Test
    func selectAllTapped_清單有篩選_只選相符訂單() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", status: .quoting),
            makeOrder(id: "B", status: .delivered),
        ])
        state.selectedStatus = .status(.quoting)

        // When
        OrdersBatchOperations.selectAllTapped(state: &state)

        // Then
        #expect(state.selectedOrderIDs == ["A"])
    }

    /// 驗證已有選取時清空所有選取的訂單
    @Test
    func clearSelectionTapped_已有選取_清空集合() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedOrderIDs = ["A", "B"]

        // When
        OrdersBatchOperations.clearSelectionTapped(state: &state)

        // Then
        #expect(state.selectedOrderIDs.isEmpty)
    }

    /// 目標狀態為已合併時不改任何訂單，多選與選取都保留
    @Test
    func batchStatusChanged_目標為已合併_保留狀態與選取() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [makeOrder(id: "A", status: .quoting)])
        state.isSelecting = true
        state.selectedOrderIDs = ["A"]

        // When
        let changed = OrdersBatchOperations.batchStatusChanged(.merged, state: &state)

        // Then
        #expect(changed == nil)
        #expect(state.isSelecting == true)
        #expect(state.selectedOrderIDs == ["A"])
        #expect(state.orders[0].status == .quoting)
    }

    /// 只更新已選且狀態不同的訂單
    @Test
    func batchStatusChanged_混合狀態與選取_只請求實際變更() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", status: .quoting),
            makeOrder(id: "B", status: .delivered),
            makeOrder(id: "C", status: .quoting),
        ])
        // B 已達目標狀態，C 未選取；兩者都不應更新
        state.selectedOrderIDs = ["A", "B"]

        // When
        let changed = OrdersBatchOperations.batchStatusChanged(.delivered, state: &state)

        // Then
        #expect(changed?.map(\.id) == ["A"])
    }

    /// 沒有訂單實際變更時仍退出多選並清空選取
    @Test
    func batchStatusChanged_狀態沒有變更_退出並清空選取() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", status: .delivered),
        ])
        state.isSelecting = true
        state.selectedOrderIDs = ["A"]
        // 目標狀態與現況相同：無訂單實際變更

        // When
        let changed = OrdersBatchOperations.batchStatusChanged(.delivered, state: &state)

        // Then
        #expect(changed == nil)
        #expect(state.isSelecting == false)
        #expect(state.selectedOrderIDs.isEmpty)
    }

    /// 批次成功回應經寫入子層，依編號套用變更並保留其他訂單
    @Test
    @MainActor
    func writes_批次寫入成功_依編號套用變更() async {
        // Given
        let initialOrders = [
            makeOrder(id: "A", status: .quoting),
            makeOrder(id: "B", status: .quoting),
        ]
        let updated = makeOrder(id: "A", status: .delivered)
        let store = TestStore(initialState: OrdersFeature.State(orders: initialOrders)) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.batchStatusResponse(.success([updated])))) {
            $0.$orders.withLock {
                $0[0] = updated
            }
        }

        // Then
        #expect(store.state.orders[0].status == .delivered)
        #expect(store.state.orders[1].status == .quoting)
    }
}

// MARK: - Private Method

private extension OrdersBatchOperationsTests {

    /// 建立僅供批次測試使用的最小訂單；非相關欄位以零值或佔位填入
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    /// - Returns: 建立的測試訂單
    func makeOrder(id: String, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶\(id)", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            categories: ["類別"],
            paymentMethod: "付款",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
