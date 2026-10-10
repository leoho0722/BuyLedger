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

/// 驗證 `OrdersDetailNavigationFeature.State` 的詳情推入、右欄同步、堆疊移除與寫入結果套用
struct OrdersDetailNavigationFeatureTests {

}

extension OrdersDetailNavigationFeatureTests {

    /// 推入訂單詳情時先清空既有堆疊，堆疊只剩指定訂單的詳情
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

    /// 找不到指定訂單時堆疊維持原樣，不清空也不推入
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

    /// 同一訂單識別值時沿用既有的右欄詳情，不改由共用訂單重建
    @Test
    func syncRegularDetail_相同訂單識別值_沿用既有詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A", itemCost: 200)])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        state.regularDetail = OrderDetailFeature.State(
            orderID: "A",
            orders: SharedReader(value: [LedgerOrder.fixture(id: "A", itemCost: 100)])
        )

        // When
        state.syncRegularDetail(selectedOrderID: "A")

        // Then
        #expect(state.regularDetail?.orderID == "A")
        #expect(state.regularDetail?.order?.itemCost == 100)
    }

    /// 換成不同的訂單識別值時重建右欄詳情，內容改讀共用訂單
    @Test
    func syncRegularDetail_不同訂單識別值_重建為新訂單詳情() {
        // Given
        let shared = Shared(value: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B", itemCost: 300),
        ])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        state.regularDetail = OrderDetailFeature.State(
            orderID: "A",
            orders: SharedReader(value: [LedgerOrder.fixture(id: "A", itemCost: 100)])
        )

        // When
        state.syncRegularDetail(selectedOrderID: "B")

        // Then
        #expect(state.regularDetail?.orderID == "B")
        #expect(state.regularDetail?.order?.itemCost == 300)
    }

    /// 清單沒有選取時清空右欄詳情
    @Test
    func syncRegularDetail_選取為nil_清空右欄詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A")])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // When
        state.syncRegularDetail(selectedOrderID: nil)

        // Then
        #expect(state.regularDetail == nil)
    }

    /// 選取的訂單已不在共用訂單中時清空右欄詳情
    @Test
    func syncRegularDetail_選取訂單不存在_清空右欄詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A")])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // When
        state.syncRegularDetail(selectedOrderID: "missing")

        // Then
        #expect(state.regularDetail == nil)
    }

    /// 初始化時右欄預設顯示共用訂單的第一筆，堆疊為空
    @Test
    func init_共用訂單非空_預設第一筆() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])

        // When
        let state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // Then
        #expect(state.regularDetail?.orderID == "A")
        #expect(state.path.isEmpty)
    }

    /// 初始化時共用訂單為空，右欄沒有詳情
    @Test
    func init_共用訂單為空_右欄為空() {
        // Given
        let shared = Shared<[LedgerOrder]>(value: [])

        // When
        let state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))

        // Then
        #expect(state.regularDetail == nil)
    }

    /// 移除指定訂單的詳情與其後的元素，前方元素保留原本的識別值
    @Test
    func popDetail_訂單位於中間_保留前方元素識別值() {
        // Given
        let orders = SharedReader(value: [LedgerOrder.fixture(id: "A")])
        var path = StackState<OrdersDetailNavigationFeature.Path.State>()
        path.append(Self.makeDetailElement("A", orders: orders))
        path.append(Self.makeDetailElement("B", orders: orders))
        path.append(Self.makeDetailElement("C", orders: orders))
        let idOfA = Array(path.ids)[0]

        // When
        path.popDetail(orderID: "B")

        // Then
        #expect(Array(path.ids) == [idOfA])
        #expect(path.first?.detail?.orderID == "A")
    }

    /// 指定訂單不在堆疊中時堆疊維持不動
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

    /// 載入後共用訂單已不含中間的詳情，該詳情與其後的元素一併移除，前方元素保留識別值
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
        let idOfA = Array(state.path.ids)[0]
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "C")]
        }

        // When
        state.applyLoadedOrders(selectedOrderID: "A")

        // Then
        #expect(state.path.count == 1)
        #expect(Array(state.path.ids) == [idOfA])
    }

    /// 載入後堆疊中的訂單都仍存在時堆疊維持不動
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
        state.applyLoadedOrders(selectedOrderID: "A")

        // Then
        #expect(state.path.ids == idsBefore)
    }

    /// 載入後堆疊第一筆訂單已不存在時整個堆疊清空
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
        state.applyLoadedOrders(selectedOrderID: "B")

        // Then
        #expect(state.path.isEmpty)
    }

    /// 冷啟動時右欄沒有詳情，載入完成後右欄依清單選取顯示該訂單
    @Test
    func applyLoadedOrders_冷啟動右欄為空_右欄顯示選取的訂單() {
        // Given
        let shared = Shared<[LedgerOrder]>(value: [])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        shared.withLock { $0 = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")] }

        // When
        state.applyLoadedOrders(selectedOrderID: "A")

        // Then
        #expect(state.regularDetail?.orderID == "A")
        #expect(state.regularDetail?.order?.id == "A")
    }

    /// 寫入結果列出的詳情識別值會逐一移除對應詳情，前方元素保留識別值
    @Test
    func apply_詳情移除識別值_移除指定詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        let orders = SharedReader(shared)
        var state = OrdersDetailNavigationFeature.State(orders: orders)
        state.path.append(Self.makeDetailElement("A", orders: orders))
        state.path.append(Self.makeDetailElement("B", orders: orders))
        let idOfA = Array(state.path.ids)[0]
        var outcome = OrdersWriteOutcome()
        outcome.detailPopIDs = ["B"]

        // When
        state.apply(outcome)

        // Then
        #expect(Array(state.path.ids) == [idOfA])
    }

    /// 合併失敗旗標開啟時，移除共用訂單已不存在的詳情，前方元素保留識別值
    @Test
    func apply_合併失敗旗標_移除已不存在的詳情() {
        // Given
        let shared = Shared(value: [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")])
        var state = OrdersDetailNavigationFeature.State(orders: SharedReader(shared))
        state.path.append(Self.makeDetailElement("A", orders: SharedReader(shared)))
        state.path.append(Self.makeDetailElement("B", orders: SharedReader(shared)))
        let idOfA = Array(state.path.ids)[0]
        shared.withLock {
            $0 = [LedgerOrder.fixture(id: "A")]
        }
        var outcome = OrdersWriteOutcome()
        outcome.shouldPopUnavailableDetails = true

        // When
        state.apply(outcome)

        // Then
        #expect(Array(state.path.ids) == [idOfA])
    }

    /// 未設定合併失敗旗標時，即使共用訂單已不含某筆訂單，堆疊仍維持不動
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
