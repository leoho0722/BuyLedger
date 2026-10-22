//
//  OrderFilterFeatureTests+Clear.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderFilterFeatureTests {

    /// 在同一份暫存中切換類別時，先前選取的日期與付款方式保留且不提交
    @Test
    func filterPendingCategoryToggled_暫存已有日期與付款方式_保留其他暫存且不提交() async {
        // Given
        var state = Self.makeState(categories: ["beauty"])
        state.pendingFilterSelection.datePeriod = .thisMonth
        state.pendingFilterSelection.paymentMethod = "轉帳"
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled("beauty"))) {
            $0.pendingFilterSelection.categories = ["beauty"]
        }

        // Then
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.pendingFilterSelection.paymentMethod == "轉帳")
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
    }

    /// 清除只重設暫存三欄，已套用值與呈現狀態保持原值，仍需套用或捨棄
    @Test
    func filterClearTapped_已套用三欄非預設_只清除暫存且仍有未套用變更() async {
        // Given
        let committed = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty", "books"],
            paymentMethod: "信用卡"
        )
        var state = Self.makeState(
            categories: ["beauty", "books"],
            committedFilterSelection: committed
        )
        state.filterSheetSearchText = "食"
        state.isSearchFieldFocused = true
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped)) {
            $0.pendingFilterSelection.datePeriod = .all
            $0.pendingFilterSelection.categories = []
            $0.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        #expect(store.state.committedFilterSelection == committed)
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == true)
        #expect(store.state.filterSheetSearchText == "食")
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.categoryGroupExpansion.expandedKinds == [.ongoing])
    }

    /// 已套用值為預設時，清除暫存變更會恢復為未修改狀態
    @Test
    func filterClearTapped_只有暫存三欄已變更_清除後不再有未套用變更() async {
        // Given
        var state = Self.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty", "books"],
            paymentMethod: "信用卡"
        )
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped)) {
            $0.pendingFilterSelection.datePeriod = .all
            $0.pendingFilterSelection.categories = []
            $0.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == false)
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
    }

    /// 暫存已為預設時清除維持未修改，供畫面衍生停用狀態
    @Test
    func filterClearTapped_暫存已是預設_維持停用與未變更() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterClearTapped))

        // Then
        #expect(store.state.pendingFilterSelection.isActive == false)
        #expect(store.state.hasUnappliedFilterChanges == false)
    }

    /// 清除後套用才提交預設值並關閉，沒有選取變更時不委派選取
    @Test
    func destination_清除後套用_提交預設並還原全部摘要() async {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", category: "beauty", paymentMethod: "信用卡"),
            OrdersFeatureTests.makeOrder(id: "B", category: "books", paymentMethod: "現金"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty", "books"]
        state.selectedPaymentMethod = "信用卡"
        state.selectedOrderID = "A"
        state.destination = .filterSheet(Self.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: [],
                paymentMethod: nil
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
            OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        ) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
            $0.destination = nil
        }
        #expect(store.state.filterSummary(language: .traditionalChinese) == "全部")
        #expect(store.state.selectedOrderID == "A")
        #expect(store.state.destination == nil)
    }

    /// 三項暫存一起套用，以全部新條件重選第一筆，只接收一次選取委派
    @Test
    func destination_三項暫存都變更_提交完整條件並重選一次() async {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "snacks", category: "snacks", paymentMethod: "轉帳"),
            OrdersFeatureTests.makeOrder(id: "beauty", category: "beauty", paymentMethod: "轉帳"),
            OrdersFeatureTests.makeOrder(id: "card", category: "beauty", paymentMethod: "信用卡"),
        ])
        state.selectedOrderID = "card"
        state.destination = .filterSheet(Self.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
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
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "轉帳"
            )
        ) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedCategories = ["beauty"]
            $0.selectedPaymentMethod = "轉帳"
            $0.selectedOrderID = "beauty"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "beauty")
        #expect(store.state.filterSummary(language: .traditionalChinese) == "本月 · beauty · 轉帳")
        #expect(store.state.destination == nil)
    }

    /// 已取消原類別的暫存再次選回後，與已套用集合相同而不再有未套用變更
    @Test
    func filterPendingCategoryToggled_暫存已取消原類別_選回後不再有未套用變更() async {
        // Given
        var state = Self.makeState(
            categories: ["beauty"],
            committedFilterSelection: OrderFilterSelection(categories: ["beauty"])
        )
        state.pendingFilterSelection.categories = []
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled("beauty"))) {
            $0.pendingFilterSelection.categories = ["beauty"]
        }

        // Then
        #expect(store.state.hasUnappliedFilterChanges == false)
        #expect(store.state.filterDiscardConfirmation == nil)
        #expect(store.state.committedFilterSelection.categories == ["beauty"])
    }
}
