//
//  OrdersFeatureDetailTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證訂單詳情與清單選取、刪除及合併結果的同步
@MainActor
struct OrdersFeatureDetailTests {

    /// 驗證選取訂單後右欄同步顯示詳情，確認刪除該訂單後右欄清空
    @Test
    func presentation_選取後刪除同一訂單_清空右欄詳情() async {
        // Given
        var initial = OrdersFeature.State(orders: [LedgerOrder.fixture(id: "A")])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedOrderID = "A"
        initial.detail.syncRegularDetail(selectedOrderID: initial.list.selectedOrderID)
        initial.presentation.destination = .alert(
            OrdersFeatureTestSupport.expectedDeletionConfirmation(
                orderID: "A",
                customerName: "測試客戶"
            )
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.removeOrder = { _ in
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.alert(.confirmDelete("A")))))) {
            $0.presentation.destination = nil
        }

        // Then
        await store.receive(\.presentation.delegate.deleteConfirmed, "A") {
            $0.$orders.withLock {
                $0 = []
            }
        }
        await store.receive(\.writes.deleteRequested)
        await store.receive(\.writes.deleteResponse)
        await store.receive(\.writes.delegate.deleted, "A") {
            $0.list.selectedOrderID = nil
        }
        #expect(store.state.detail.regularDetail?.orderID == "A")
        await store.receive(\.list.delegate.selectionChanged, nil) {
            $0.detail.regularDetail = nil
        }
        #expect(store.state.detail.regularDetail == nil)
        #expect(store.state.list.selectedOrderID == nil)
    }

    /// 驗證刪除已選訂單且仍有其他訂單時，清單改選剩餘的第一筆，右欄同步顯示它的詳情
    @Test
    func writes_刪除已選訂單且仍有訂單_同步右欄下一筆() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedOrderID = "A"
        initial.detail.syncRegularDetail(selectedOrderID: initial.list.selectedOrderID)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.deleteResponse(.success("A")))) {
            $0.$orders.withLock {
                $0.removeAll {
                    $0.id == "A"
                }
            }
        }

        // Then
        await store.receive(\.writes.delegate.deleted, "A") {
            $0.list.selectedOrderID = "B"
        }
        await store.receive(\.list.delegate.selectionChanged, "B") {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "B",
                orders: SharedReader(initial.$orders)
            )
        }
        #expect(store.state.detail.regularDetail?.order?.id == "B")
    }

    /// 驗證刪除最後推入的那筆訂單時，只移除它的詳情，更早推入的詳情維持原樣
    @Test
    func writes_刪除堆疊後方訂單_保留前方詳情識別值() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.detail.path.append(
            .detail(OrderDetailFeature.State(orderID: "A", orders: SharedReader(initial.$orders)))
        )
        initial.detail.path.append(
            .detail(OrderDetailFeature.State(orderID: "B", orders: SharedReader(initial.$orders)))
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.deleteResponse(.success("B")))) {
            $0.$orders.withLock {
                $0.removeAll {
                    $0.id == "B"
                }
            }
        }

        // Then
        await store.receive(\.writes.delegate.deleted, "B") {
            $0.detail.path.removeLast()
        }
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.ids.first == 0)
        #expect(store.state.detail.path.first?.detail?.orderID == "A")
    }

    /// 驗證來源訂單的詳情正在顯示時，合併完成後清空推入的詳情，右欄改選合併後的新訂單
    @Test
    func writes_合併來源正顯示詳情_移除來源並同步結果() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A"]),
            LedgerOrder.fixture(id: "A", status: .merged),
        ])
        initial.list.selectedOrderID = "A"
        initial.detail.syncRegularDetail(selectedOrderID: initial.list.selectedOrderID)
        initial.detail.showDetail(orderID: "A")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.delegate(.merged(id: "M")))) {
            $0.list.selectedOrderID = "M"
            $0.detail.path.removeAll()
        }

        // Then
        await store.receive(\.list.delegate.selectionChanged, "M") {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "M",
                orders: SharedReader(initial.$orders)
            )
        }
        #expect(store.state.detail.path.isEmpty)
        #expect(store.state.detail.regularDetail?.order?.id == "M")
    }

    /// 驗證清單由 A 改選 B 時，右欄改為顯示 B 的詳情
    @Test
    func list_由訂單甲換選乙_右欄同步新的訂單() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.list.selectedOrderID = "A"
        initial.detail.syncRegularDetail(selectedOrderID: initial.list.selectedOrderID)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.view(.orderSelected("B")))) {
            $0.list.selectedOrderID = "B"
        }

        // Then
        await store.receive(\.list.delegate.selectionChanged, "B") {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "B",
                orders: SharedReader(initial.$orders)
            )
        }
        #expect(store.state.detail.regularDetail?.orderID == "B")
        #expect(store.state.detail.regularDetail?.order?.id == "B")
    }

    /// 驗證訂單狀態改成篩選外的狀態後，仍保留選取並在右欄更新內容，清單篩選結果為空
    @Test
    func writes_詳情改成篩選外狀態_保留選取並更新右欄內容() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A", status: .confirmed),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedStatus = .status(.confirmed)
        initial.list.selectedOrderID = "A"
        initial.detail.syncRegularDetail(selectedOrderID: initial.list.selectedOrderID)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }
        let changed = LedgerOrder.fixture(id: "A", status: .arrived)

        // When
        await store.send(.writes(.statusResponse(.success(changed)))) {
            $0.$orders.withLock {
                $0 = [changed]
            }
        }

        // Then
        #expect(store.state.list.selectedOrderID == "A")
        #expect(store.state.detail.regularDetail?.orderID == "A")
        #expect(store.state.detail.regularDetail?.order?.status == .arrived)
        #expect(store.state.list.filteredOrders.isEmpty)
    }

    /// 驗證訂單載入完成後，自動選取第一筆，右欄同步顯示該筆詳情
    @Test
    func load_收到訂單回應_右欄同步第一筆詳情() async {
        // Given
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let order = LedgerOrder.fixture(id: "A")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.load(.loadResponse(.init(orders: .success([order]))))) {
            $0.$orders.withLock {
                $0 = [order]
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.list.selectedOrderID = "A"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "A",
                orders: SharedReader(initial.$orders)
            )
        }

        // Then
        #expect(store.state.detail.regularDetail?.order?.id == "A")
    }

    /// 驗證詳情已顯示 A 時點擊 B，詳情路徑清空後只推入 B 的詳情
    @Test
    func list_詳情已顯示甲時點擊乙_只留下乙的詳情() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.detail.showDetail(orderID: "A")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.view(.orderTapped("B"))))

        // Then
        await store.receive(\.list.delegate.requested, .showDetail("B")) {
            $0.detail.path.removeAll()
            $0.detail.path[id: 1] = .detail(
                OrderDetailFeature.State(orderID: "B", orders: SharedReader(initial.$orders))
            )
        }
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.first?.detail?.orderID == "B")
    }
}
