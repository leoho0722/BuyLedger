//
//  OrderListFeatureTests+FilterDelegates.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 套用多類別取交集後重選第一筆，僅委派一次選取變更
    @Test
    func destination_套用多類別_重選第一筆並委派一次() async {
        // Given
        var state = Self.makeState(orders: [
            LedgerOrder.fixture(id: "outside", categories: ["snacks"]),
            LedgerOrder.fixture(id: "books", categories: ["books"]),
            LedgerOrder.fixture(id: "beauty", categories: ["beauty"]),
        ])
        state.selectedOrderID = "outside"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection.categories = ["beauty", "books"]
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(categories: ["beauty", "books"])
        ) {
            $0.selectedCategories = ["beauty", "books"]
            $0.selectedOrderID = "books"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "books")
        #expect(store.state.filteredOrders.map(\.id) == ["books", "beauty"])
    }

    /// 相同類別集合不受排列影響，套用時保留第二筆選取且不委派變更
    @Test
    func destination_多類別集合相同_關閉且保留選取() async {
        // Given
        var state = Self.makeState(orders: [
            LedgerOrder.fixture(id: "A", categories: ["beauty"]),
            LedgerOrder.fixture(id: "B", categories: ["books"]),
        ])
        state.selectedCategories = Set(["beauty", "books"])
        state.selectedOrderID = "B"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection.categories = Set(["books", "beauty"])
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(categories: ["beauty", "books"])
        ) {
            $0.destination = nil
        }
        #expect(store.state.selectedOrderID == "B")
        #expect(store.state.selectedCategories == ["beauty", "books"])
    }

    /// 子層套用時提交三欄，保留狀態與搜尋並關閉唯一目的地
    @Test
    func destination_套用三欄篩選_保留狀態搜尋並關閉目的地() async {
        // Given
        var state = Self.makeState()
        state.selectedStatus = .shipping
        state.searchText = "林"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["美妝"],
                paymentMethod: "信用卡"
            )
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(datePeriod: .thisMonth, categories: ["美妝"], paymentMethod: "信用卡")
        ) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedCategories = ["美妝"]
            $0.selectedPaymentMethod = "信用卡"
            $0.destination = nil
        }
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedCategories == ["美妝"])
        #expect(store.state.selectedPaymentMethod == "信用卡")
        #expect(store.state.selectedStatus == .shipping)
        #expect(store.state.searchText == "林")
        #expect(store.state.destination == nil)
    }

    /// 面板開啟期間改已套用日期，未套用變更沿用目前清單的比較基準
    @Test
    func datePeriodSelected_篩選面板開啟中_同步子層已套用值() async {
        // Given
        var state = Self.makeState()
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.datePeriodSelected(.thisMonth))) {
            $0.selectedDatePeriod = .thisMonth
            $0.destination?.modify(\.filterSheet) {
                $0.committedFilterSelection.datePeriod = .thisMonth
            }
        }

        // Then
        await store.receive(\.delegate.selectionChanged, nil)
        #expect(
            store.state.destination?.filterSheet?.committedFilterSelection.datePeriod
                == .thisMonth
        )
        #expect(store.state.destination?.filterSheet?.pendingFilterSelection.datePeriod == .all)
        #expect(store.state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
    }

    /// Root 的跨功能導覽直接更新清單時，仍同步面板比較基準並保留付款方式
    @Test
    func applyFilterNavigation_篩選面板開啟中_同步子層並保留付款方式() {
        // Given
        var state = Self.makeState()
        state.selectedStatus = .shipping
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["美妝"]
        state.selectedPaymentMethod = "信用卡"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection()
        }

        // When
        state.applyFilterNavigation(searchText: "林", category: nil)

        // Then
        #expect(state.selectedStatus == .all)
        #expect(state.searchText == "林")
        #expect(state.destination?.filterSheet?.committedFilterSelection.datePeriod == .all)
        #expect(state.destination?.filterSheet?.committedFilterSelection.categories == [])
        #expect(state.destination?.filterSheet?.committedFilterSelection.paymentMethod == "信用卡")
        #expect(state.destination?.filterSheet?.pendingFilterSelection.paymentMethod == nil)
        #expect(state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
    }
}
