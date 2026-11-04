//
//  OrdersDetailNavigationFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersDetailNavigationFeature.State` 的單元測試，涵蓋詳情路徑、堆疊移除與寫入結果的套用
struct OrdersDetailNavigationFeatureTests {

    /// 驗證推入訂單詳情時，先清空既有堆疊，堆疊只剩指定訂單的詳情，且堆疊識別值已更換
    @Test
    func showDetail_訂單存在_清空舊堆疊後只推入該訂單() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        state.path.append(Self.makeDetailElement("B", orders: orders))
        let idsBefore = state.path.ids

        // When
        state.showDetail(orderID: "A")

        // Then
        #expect(state.path.count == 1)
        #expect(state.path.first?.detail?.orderID == "A")
        #expect(state.path.ids != idsBefore)
    }

    /// 驗證推入的訂單不存在時，堆疊的識別值與內容維持原樣，不清空也不推入
    @Test
    func showDetail_訂單不存在_堆疊維持不動() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        let idsBefore = state.path.ids

        // When
        state.showDetail(orderID: "missing")

        // Then
        #expect(state.path.ids == idsBefore)
        #expect(state.path.first?.detail?.orderID == "A")
    }

    /// 驗證共用訂單非空時，初始化不自動開啟詳情
    @Test
    func init_共用訂單非空_不自動開啟詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])

        // When
        let state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // Then
        #expect(state.path.isEmpty)
    }

    /// 驗證共用訂單為空時，初始化後詳情路徑為空
    @Test
    func init_共用訂單為空_詳情路徑為空() {
        // Given
        let shared = Shared<[LedgerOrder]>(value: [])

        // When
        let state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // Then
        #expect(state.path.isEmpty)
    }

    /// 驗證 `popDetail` 移除位於中間的訂單詳情與其後的元素，前方元素保留原本的識別值
    @Test
    func popDetail_訂單位於中間_保留前方元素識別值() {
        // Given
        let orders = SharedReader(value: [LedgerOrder.fixture(id: "A")])
        var path = StackState<OrdersDetailNavigationFeature.Path.State>()
        path.append(Self.makeDetailElement("A", orders: orders))
        path.append(Self.makeDetailElement("B", orders: orders))
        path.append(Self.makeDetailElement("C", orders: orders))

        // When
        path.popDetail(orderID: "B")

        // Then
        #expect(Array(path.ids) == [0])
        #expect(path.first?.detail?.orderID == "A")
    }

    /// 驗證 `popDetail` 指定的訂單不在堆疊中時，堆疊維持不動
    @Test
    func popDetail_訂單不在堆疊中_堆疊維持不動() {
        // Given
        let orders = SharedReader(value: [LedgerOrder.fixture(id: "A")])
        var path = StackState<OrdersDetailNavigationFeature.Path.State>()
        path.append(Self.makeDetailElement("A", orders: orders))
        let idsBefore = path.ids

        // When
        path.popDetail(orderID: "missing")

        // Then
        #expect(path.ids == idsBefore)
    }

    /// 驗證 `applyLoadedOrders` 發現中間的訂單已不在共用訂單中時，移除該詳情與其後的元素，前方元素保留識別值
    @Test
    func applyLoadedOrders_中間訂單已不存在_移除該詳情與其後元素() {
        // Given
        let shared = Shared(value: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(id: "C"),
        ])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        state.path.append(Self.makeDetailElement("B", orders: orders))
        state.path.append(Self.makeDetailElement("C", orders: orders))
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "C")]
        }

        // When
        state.applyLoadedOrders()

        // Then
        #expect(state.path.count == 1)
        #expect(Array(state.path.ids) == [0])
    }

    /// 驗證 `applyLoadedOrders` 時堆疊中的訂單都仍存在，堆疊維持不動
    @Test
    func applyLoadedOrders_所有訂單仍存在_堆疊維持不動() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        state.path.append(Self.makeDetailElement("B", orders: orders))
        let idsBefore = state.path.ids

        // When
        state.applyLoadedOrders()

        // Then
        #expect(state.path.ids == idsBefore)
    }

    /// 驗證 `applyLoadedOrders` 發現堆疊第一筆訂單已不存在時，整個堆疊清空
    @Test
    func applyLoadedOrders_首筆訂單已不存在_堆疊清空() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "B")]
        }

        // When
        state.applyLoadedOrders()

        // Then
        #expect(state.path.isEmpty)
    }

    /// 驗證冷啟動後載入訂單不會自動開啟詳情
    @Test
    func applyLoadedOrders_冷啟動載入訂單_維持詳情路徑為空() {
        // Given
        let shared = Shared<[LedgerOrder]>(value: [])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        shared.withLock { $0 = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")] }

        // When
        state.applyLoadedOrders()

        // Then
        #expect(state.path.isEmpty)
    }

    /// 驗證 `apply` 套用寫入結果時，依 `detailPopIDs` 移除對應的詳情，前方元素保留識別值
    @Test
    func apply_詳情移除識別值_移除指定詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        state.path.append(Self.makeDetailElement("B", orders: orders))
        var outcome = OrdersWriteOutcome()
        outcome.detailPopIDs = ["B"]

        // When
        state.apply(outcome)

        // Then
        #expect(Array(state.path.ids) == [0])
    }

    /// 驗證合併失敗旗標 (`shouldPopUnavailableDetails`) 開啟時，`apply` 移除共用訂單已不存在的詳情，前方元素保留識別值
    @Test
    func apply_合併失敗旗標_移除已不存在的詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        state.path.append(Self.makeDetailElement("A", orders: SharedReader(shared)))
        state.path.append(Self.makeDetailElement("B", orders: SharedReader(shared)))
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "A")]
        }
        var outcome = OrdersWriteOutcome()
        outcome.shouldPopUnavailableDetails = true

        // When
        state.apply(outcome)

        // Then
        #expect(Array(state.path.ids) == [0])
    }

    /// 驗證合併失敗旗標 (`shouldPopUnavailableDetails`) 未設定時，即使共用訂單已不含堆疊中的某筆訂單，`apply` 仍維持堆疊不動
    @Test
    func apply_未設定合併失敗旗標_堆疊維持不動() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        state.path.append(Self.makeDetailElement("A", orders: SharedReader(shared)))
        state.path.append(Self.makeDetailElement("B", orders: SharedReader(shared)))
        let idsBefore = state.path.ids
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "A")]
        }
        let outcome = OrdersWriteOutcome()

        // When
        state.apply(outcome)

        // Then
        #expect(state.path.ids == idsBefore)
    }
}

// MARK: - Private Method

private extension OrdersDetailNavigationFeatureTests {

    /// 以指定的共用訂單引用建立詳情堆疊元素，供堆疊的前置條件使用
    ///
    /// - Parameters:
    ///   - orderID: 要顯示的訂單識別值
    ///   - orders: 詳情讀取的共用訂單引用
    /// - Returns: 包成詳情堆疊元素的詳情狀態
    static func makeDetailElement(
        _ orderID: LedgerOrder.ID,
        orders: SharedReader<[LedgerOrder]>
    ) -> OrdersDetailNavigationFeature.Path.State {
        .detail(OrderDetailFeature.State(orderID: orderID, orders: orders))
    }
}
