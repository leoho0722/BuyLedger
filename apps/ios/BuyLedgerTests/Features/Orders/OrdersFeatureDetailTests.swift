//
//  OrdersFeatureDetailTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 `TestStore` 驗證詳情路徑與寫入結果同步
@MainActor
struct OrdersFeatureDetailTests {

    /// 驗證刪除目前詳情訂單後清空詳情路徑
    @Test
    func presentation_刪除目前詳情訂單_清空詳情path() async {
        // Given
        var initial = OrdersFeature.State(orders: [LedgerOrder.fixture(id: "A")])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.detail.showDetail(orderID: "A")
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
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證刪除目前詳情訂單且仍有其他訂單時，清空詳情路徑
    @Test
    func writes_刪除目前詳情訂單且仍有其他訂單_清空path() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.detail.showDetail(orderID: "A")
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
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
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

    /// 驗證合併移除目前詳情的來源後清空路徑，不開啟合併結果
    @Test
    func writes_合併目前詳情來源_清除詳情且不開啟結果() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A"]),
            LedgerOrder.fixture(id: "A", status: .merged),
        ])
        initial.detail.showDetail(orderID: "A")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.delegate(.merged(id: "M")))) {
            $0.detail.path.removeAll()
        }

        // Then
        await store.finish()
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證合併不影響目前詳情時保留原訂單與 `path` 元素識別值
    @Test
    func writes_合併無關訂單_保留目前詳情與path識別值() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A", "B"]),
            LedgerOrder.fixture(id: "A", status: .merged),
            LedgerOrder.fixture(id: "B", status: .merged),
            LedgerOrder.fixture(id: "D"),
        ])
        initial.detail.showDetail(orderID: "D")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.delegate(.merged(id: "M"))))

        // Then
        await store.finish()
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.first?.detail?.orderID == "D")
    }

    /// 驗證批次勾選其他訂單後，保留目前詳情路徑及元素識別值
    @Test
    func list_批次勾選其他訂單_保留目前詳情path() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "BL-2604-017"),
            LedgerOrder.fixture(id: "BL-2604-012"),
            LedgerOrder.fixture(id: "BL-2604-018"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.detail.showDetail(orderID: "BL-2604-017")
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["BL-2604-012"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.view(.orderSelectionToggled("BL-2604-018")))) {
            $0.list.selectedOrderIDs = ["BL-2604-012", "BL-2604-018"]
        }

        // Then
        await store.finish()
        #expect(store.state.list.selectedOrderIDs == ["BL-2604-012", "BL-2604-018"])
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail?.orderID == "BL-2604-017")
    }

    /// 驗證全選批次訂單後，保留目前詳情路徑及元素識別值
    @Test
    func list_全選批次訂單_保留目前詳情path() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "BL-2604-017"),
            LedgerOrder.fixture(id: "BL-2604-012"),
            LedgerOrder.fixture(id: "BL-2604-018"),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.detail.showDetail(orderID: "BL-2604-017")
        initial.list.isSelecting = true
        initial.list.selectedOrderIDs = ["BL-2604-012"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.view(.selectAllTapped))) {
            $0.list.selectedOrderIDs = ["BL-2604-017", "BL-2604-012", "BL-2604-018"]
        }

        // Then
        await store.finish()
        #expect(store.state.list.selectedOrderIDs == ["BL-2604-017", "BL-2604-012", "BL-2604-018"])
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail?.orderID == "BL-2604-017")
    }

    /// 驗證訂單狀態改成篩選外後，仍保留 `path` 詳情且清單篩選結果為空
    @Test
    func writes_詳情改成篩選外狀態_保留path並更新內容() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A", status: .confirmed),
        ])
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.list.selectedStatus = .status(.confirmed)
        initial.detail.showDetail(orderID: "A")
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
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail?.orderID == "A")
        #expect(store.state.detail.path.last?.detail?.order?.status == .arrived)
        #expect(store.state.list.filteredOrders.isEmpty)
    }

    /// 驗證首次載入訂單後不自動開啟詳情
    @Test
    func load_首載訂單_不自動開啟詳情() async {
        // Given
        let initial = OrdersFeature.State(orders: [])
        let updatedOrders = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")]
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.load(.loadResponse(.init(orders: .success(updatedOrders))))) {
            $0.$orders.withLock {
                $0 = updatedOrders
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
        }

        // Then
        #expect(store.state.orders.map(\.id) == ["A", "B"])
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證刷新仍包含目前詳情訂單時，保留原 `path` 識別值與詳情
    @Test
    func load_刷新仍包含目前詳情_保留path識別值與詳情() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "B"),
            LedgerOrder.fixture(id: "A"),
        ])
        initial.detail.showDetail(orderID: "B")
        initial.load.$hasLoaded.withLock {
            $0 = true
        }
        let updatedOrders = [LedgerOrder.fixture(id: "A"), LedgerOrder.fixture(id: "B")]
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.load(.loadResponse(.init(orders: .success(updatedOrders))))) {
            $0.$orders.withLock {
                $0 = updatedOrders
            }
        }

        // Then
        #expect(store.state.orders.map(\.id) == ["A", "B"])
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail?.orderID == "B")
    }

    /// 驗證載入移除詳情訂單時清空失效 `path`，不會自動選取相鄰訂單
    @Test
    func load_詳情訂單合併後消失_清空失效path() async {
        // Given
        let mergedOrder = LedgerOrder.fixture(id: "M", mergedSourceIDs: ["A"])
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.detail.showDetail(orderID: "A")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(
            .load(
                .loadResponse(.init(orders: .success([mergedOrder, LedgerOrder.fixture(id: "B")])))
            )
        ) {
            $0.$orders.withLock {
                $0 = [mergedOrder, LedgerOrder.fixture(id: "B")]
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.detail.path.removeAll()
        }

        // Then
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證原生清單取消選取時清空目前詳情路徑
    @Test
    func detailSelectionChanged_原生返回清單_清空path() async {
        // Given
        var initial = OrdersFeature.State(orders: [LedgerOrder.fixture(id: "A")])
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.detailSelectionChanged(nil))) {
            $0.detail.path.removeAll()
        }

        // Then
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證原生清單重選目前訂單時保留同一個詳情路徑元素
    @Test
    func detailSelectionChanged_重選目前訂單_保留path元素識別值() async {
        // Given
        var initial = OrdersFeature.State(orders: [LedgerOrder.fixture(id: "A")])
        initial.detail.showDetail(orderID: "A")
        let initialPathIDs = Array(initial.detail.path.ids)
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.detailSelectionChanged("A")))

        // Then
        #expect(Array(store.state.detail.path.ids) == initialPathIDs)
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.first?.detail?.orderID == "A")
    }

    /// 驗證原生清單選取不存在的訂單時保留目前詳情 `path`
    @Test
    func detailSelectionChanged_訂單不存在_保留path() async {
        // Given
        var initial = OrdersFeature.State(orders: [LedgerOrder.fixture(id: "A")])
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)
        let initialPathIDs = Array(store.state.detail.path.ids)

        // When
        await store.send(.view(.detailSelectionChanged("missing")))

        // Then
        #expect(Array(store.state.detail.path.ids) == initialPathIDs)
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.last?.detail?.orderID == "A")
    }

    /// 驗證原生清單選取其他訂單時只留下新訂單的詳情路徑
    @Test
    func detailSelectionChanged_選取其他訂單_以新詳情取代path() async {
        // Given
        var initial = OrdersFeature.State(orders: [
            LedgerOrder.fixture(id: "A"),
            LedgerOrder.fixture(id: "B"),
        ])
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)
        let initialPathIDs = Array(store.state.detail.path.ids)

        // When
        await store.send(.view(.detailSelectionChanged("B"))) {
            $0.detail.path.removeAll()
            $0.detail.path[id: 1] = .detail(
                OrderDetailFeature.State(orderID: "B", orders: SharedReader(initial.$orders))
            )
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [1])
        #expect(Array(store.state.detail.path.ids) != initialPathIDs)
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path.first?.detail?.orderID == "B")
    }

    /// 驗證篩選面板套用排除推入詳情的類別後，下一個 action 清空詳情路徑
    @Test
    func list_篩選面板排除推入詳情_清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        initial.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.list)
        )
        let appliedSelection = OrderFilterSelection(categories: ["books"])
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .list(.destination(.presented(.filterSheet(.delegate(.applied(appliedSelection))))))
        ) {
            $0.list.selectedCategories = ["books"]
            $0.list.destination = nil
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證類別選擇器套用排除推入詳情的類別後，下一個 action 清空詳情路徑
    @Test
    func list_類別選擇器排除推入詳情_清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        initial.list.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: initial.list)
        )
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .list(.destination(.presented(.categoryPicker(.delegate(.applied(["books"]))))))
        ) {
            $0.list.selectedCategories = ["books"]
            $0.list.destination = nil
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證清單狀態篩選排除推入詳情的訂單後，下一個 action 清空詳情路徑
    @Test
    func list_狀態篩選排除推入詳情_清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.status(.arrived))))) {
            $0.list.selectedStatus = .status(.arrived)
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證直接篩選仍命中推入詳情時，保留路徑識別值與詳情子狀態
    @Test
    func list_狀態篩選仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.shipping)))) {
            $0.list.selectedStatus = .shipping
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail == retained)
    }

    /// 驗證日期篩選仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_日期篩選仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.datePeriodSelected(.thisMonth)))) {
            $0.list.selectedDatePeriod = .thisMonth
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證付款篩選仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_付款篩選仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.paymentMethodFilterSelected("付款")))) {
            $0.list.selectedPaymentMethod = "付款"
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證類別選擇器仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_類別選擇器仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        initial.list.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: initial.list)
        )
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .list(.destination(.presented(.categoryPicker(.delegate(.applied(["beauty"]))))))
        ) {
            $0.list.selectedCategories = ["beauty"]
            $0.list.destination = nil
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證篩選面板仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_篩選面板仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        initial.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.list)
        )
        let retained = initial.detail.path.first?.detail
        let appliedSelection = OrderFilterSelection(categories: ["beauty"])
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .list(.destination(.presented(.filterSheet(.delegate(.applied(appliedSelection))))))
        ) {
            $0.list.selectedCategories = ["beauty"]
            $0.list.destination = nil
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證搜尋仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_搜尋仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.searchTextChanged("客戶")))) {
            $0.list.searchText = "客戶"
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證搜尋排除目前詳情時，下一個 action 才清空 `path`
    @Test
    func list_搜尋排除推入詳情_下一個action清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.searchTextChanged("不存在")))) {
            $0.list.searchText = "不存在"
        }

        // Then
        #expect(store.state.selectedOrderID == "A")
        #expect(store.state.detail.path.count == 1)
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證日期篩選排除目前詳情時，下一個 action 清空 `path`
    @Test
    func list_日期篩選排除推入詳情_清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.datePeriodSelected(.lastMonth)))) {
            $0.list.selectedDatePeriod = .lastMonth
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證付款篩選排除目前詳情時，下一個 action 清空 `path`
    @Test
    func list_付款篩選排除推入詳情_清空path() async {
        // Given
        var initial = Self.makeInitialState()
        initial.detail.showDetail(orderID: "A")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.paymentMethodFilterSelected("其他")))) {
            $0.list.selectedPaymentMethod = "其他"
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證清除篩選仍命中目前詳情時，保留 `path` 識別值與詳情
    @Test
    func list_清除篩選仍命中推入詳情_保留path識別值與詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.list.selectedCategories = ["beauty"]
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.clearFiltersTapped))) {
            $0.list.selectedCategories = []
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.last?.detail == retained)
    }

    /// 驗證沒有詳情時清除篩選，不自動開啟任何訂單
    @Test
    func list_清除篩選且無詳情_不自動開啟詳情() async {
        // Given
        var initial = Self.makeInitialState()
        initial.list.selectedCategories = ["beauty"]
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.clearFiltersTapped))) {
            $0.list.selectedCategories = []
        }

        // Then
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證批次多選不會清除明確開啟但被目前篩選排除的詳情
    @Test
    func list_進入批次模式且詳情不符篩選_保留明確目標() async {
        // Given
        var initial = Self.makeInitialState()
        initial.list.selectedStatus = .status(.arrived)
        initial.detail.showDetail(orderID: "A")
        let retained = initial.detail.path.first?.detail
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.selectionModeToggled))) {
            $0.list.isSelecting = true
        }

        // Then
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail == retained)
    }
}

// MARK: - Private Method

private extension OrdersFeatureDetailTests {

    /// 建立注入固定時間與行事曆的訂單功能 `TestStore`
    ///
    /// - Parameter initial: 測試的初始訂單狀態
    /// - Returns: 訂單功能測試使用的 store
    static func makeStore(initial: OrdersFeature.State) -> TestStoreOf<OrdersFeature> {
        TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
    }

    /// 建立含兩筆固定訂單與已記錄日期脈絡的詳情測試初始狀態
    ///
    /// - Returns: 可供清單操作與詳情路徑測試使用的訂單狀態
    static func makeInitialState() -> OrdersFeature.State {
        var state = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "beauty", status: .shipping),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "books", status: .arrived),
        ])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }
}
