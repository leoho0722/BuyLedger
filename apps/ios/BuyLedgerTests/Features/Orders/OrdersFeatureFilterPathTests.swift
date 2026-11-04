//
//  OrdersFeatureFilterPathTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/30.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 `TestStore` 驗證篩選後的詳情路徑
@MainActor
struct OrdersFeatureFilterPathTests {

    /// 驗證篩選更新後仍命中目前詳情的訂單時，保留 BL-2604-017 的詳情路徑與詳情狀態
    @Test
    func list_篩選後仍含目的地_保留017與詳情() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.list.selectedStatus = .status(.arrived)
        initial.detail.showDetail(orderID: "BL-2604-017")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.all)))) {
            $0.list.selectedStatus = .all
        }

        // Then
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-015", "BL-2604-017"])
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail?.orderID == "BL-2604-017")
    }

    /// 驗證篩選更新後排除目前詳情的訂單時，清空詳情路徑，且不自動選取其他篩選結果
    @Test
    func list_篩選後排除目的地_清空path() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.detail.showDetail(orderID: "BL-2604-017")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.status(.shipping))))) {
            $0.list.selectedStatus = .status(.shipping)
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-015"])
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證篩選結果為空時，清空目前的詳情路徑
    @Test
    func list_篩選後結果為空_清空path() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.detail.showDetail(orderID: "BL-2604-017")
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.status(.quoting))))) {
            $0.list.selectedStatus = .status(.quoting)
        }

        // Then
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        await store.finish()
        #expect(store.state.list.filteredOrders.isEmpty)
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證沒有目的地時，篩選更新後即使有結果也維持未選取
    @Test
    func list_無目的地篩選後有結果_維持未選取() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.list.selectedStatus = .status(.quoting)
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.view(.statusFilterSelected(.all)))) {
            $0.list.selectedStatus = .all
        }

        // Then
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-015", "BL-2604-017"])
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證三項待確認篩選同時變更且目的地符合最終條件時保留詳情，套用只送出一次委派，沒有額外的目的地檢查 action
    @Test
    func list_三項待確認皆變更_目的地符合最終條件保留詳情() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.detail.showDetail(orderID: "BL-2604-017")
        initial.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.list)
        )
        initial.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        }
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.destination(.presented(.filterSheet(.view(.filterApplyTapped))))))

        // Then
        await store.receive(
            \.list.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        ) {
            $0.list.selectedDatePeriod = .thisMonth
            $0.list.selectedCategories = ["beauty"]
            $0.list.selectedPaymentMethod = "轉帳"
            $0.list.destination = nil
        }
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-017"])
        #expect(Array(store.state.detail.path.ids) == [0])
        #expect(store.state.detail.path.first?.detail?.orderID == "BL-2604-017")
    }

    /// 驗證三項待確認篩選同時變更且目的地不符最終條件時清空詳情路徑，不自動選取其他訂單
    @Test
    func list_三項待確認皆變更_目的地不符最終條件清空path() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.detail.showDetail(orderID: "BL-2604-017")
        initial.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.list)
        )
        initial.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["snacks"],
                paymentMethod: "現金"
            )
        }
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.destination(.presented(.filterSheet(.view(.filterApplyTapped))))))

        // Then
        await store.receive(
            \.list.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["snacks"],
                paymentMethod: "現金"
            )
        ) {
            $0.list.selectedDatePeriod = .thisMonth
            $0.list.selectedCategories = ["snacks"]
            $0.list.selectedPaymentMethod = "現金"
            $0.list.destination = nil
        }
        await store.receive(\.filterConditionsChanged) {
            $0.detail.path.removeAll()
        }
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-015"])
        #expect(store.state.detail.path.isEmpty)
    }

    /// 驗證三項待確認篩選同時變更且沒有目的地時，套用後目的地維持未選取
    @Test
    func list_三項待確認皆變更_無目的地維持未選取() async {
        // Given
        var initial = Self.makeOrdersState()
        initial.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.list)
        )
        initial.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        }
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.list(.destination(.presented(.filterSheet(.view(.filterApplyTapped))))))

        // Then
        await store.receive(
            \.list.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        ) {
            $0.list.selectedDatePeriod = .thisMonth
            $0.list.selectedCategories = ["beauty"]
            $0.list.selectedPaymentMethod = "轉帳"
            $0.list.destination = nil
        }
        await store.finish()
        #expect(Set(store.state.list.filteredOrders.map(\.id)) == ["BL-2604-017"])
        #expect(store.state.detail.path.isEmpty)
    }
}

// MARK: - Private Method

private extension OrdersFeatureFilterPathTests {

    /// 建立兩筆訂單的功能狀態：BL-2604-015 為出貨中、零食、現金，BL-2604-017 為已到貨、美妝、轉帳
    ///
    /// - Returns: 記錄固定日期脈絡的訂單功能狀態
    static func makeOrdersState() -> OrdersFeature.State {
        var state = OrdersFeature.State(orders: [
            OrdersFeatureTestSupport.makeOrder(
                id: "BL-2604-015",
                category: "snacks",
                status: .shipping,
                paymentMethod: "現金"
            ),
            OrdersFeatureTestSupport.makeOrder(
                id: "BL-2604-017",
                category: "beauty",
                status: .arrived,
                paymentMethod: "轉帳"
            ),
        ])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }

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
}
