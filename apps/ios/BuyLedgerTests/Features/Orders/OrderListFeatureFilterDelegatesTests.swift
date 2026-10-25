//
//  OrderListFeatureFilterDelegatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證篩選面板套用、取消與日期變更的事件處理
struct OrderListFeatureFilterDelegatesTests {

    /// 驗證套用 beauty 與 books 兩類後，訂單符合任一類別即顯示，選取重選為第一筆 books，且只通知一次選取變更
    @Test
    @MainActor
    func destination_套用多類別_重選第一筆並委派一次() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "outside", categories: ["snacks"]),
            LedgerOrder.fixture(id: "books", categories: ["books"]),
            LedgerOrder.fixture(id: "beauty", categories: ["beauty"]),
        ])
        state.selectedOrderID = "outside"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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
            OrderFilterSelection(
                datePeriod: .all,
                categories: ["beauty", "books"],
                paymentMethod: nil
            )
        ) {
            $0.selectedCategories = ["beauty", "books"]
            $0.selectedOrderID = "books"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "books")
        #expect(store.state.filteredOrders.map(\.id) == ["books", "beauty"])
    }

    /// 驗證提交的類別集合與已套用的相同 (僅排列不同) 時，清單接收套用結果並關閉篩選面板，保留選取的訂單 B，不再回報選取變更
    @Test
    @MainActor
    func destination_多類別集合相同_關閉且保留選取() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            LedgerOrder.fixture(id: "A", categories: ["beauty"]),
            LedgerOrder.fixture(id: "B", categories: ["books"]),
        ])
        state.selectedCategories = Set(["beauty", "books"])
        state.selectedOrderID = "B"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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
            OrderFilterSelection(
                datePeriod: .all,
                categories: ["beauty", "books"],
                paymentMethod: nil
            )
        ) {
            $0.destination = nil
        }
        #expect(store.state.selectedOrderID == "B")
        #expect(store.state.selectedCategories == ["beauty", "books"])
    }

    /// 驗證套用三欄篩選時，日期、類別與付款方式寫入清單，狀態與搜尋保留，並關閉篩選面板
    @Test
    @MainActor
    func destination_套用三欄篩選_保留狀態搜尋並關閉目的地() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedStatus = .shipping
        state.searchText = "林"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證篩選面板開啟時改清單的日期，面板的已套用日期同步為本月，暫存日期維持全部並視為有未套用變更
    @Test
    @MainActor
    func datePeriodSelected_篩選面板開啟中_同步子層已套用值() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證根功能的跨功能導覽直接改清單時，清單狀態改為全部，篩選面板的已套用值同步為新值並保留付款方式，暫存的付款方式仍未設定
    @Test
    func applyFilterNavigation_篩選面板開啟中_同步子層並保留付款方式() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedStatus = .shipping
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["美妝"]
        state.selectedPaymentMethod = "信用卡"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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
