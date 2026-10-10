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

    /// 子層套用時提交三欄，保留狀態、搜尋與兩個寬版選擇器旗標
    @Test
    func filterSheet_套用三欄篩選_保留狀態搜尋與選擇器() async {
        // Given
        var state = Self.makeState()
        state.selectedStatus = .shipping
        state.searchText = "林"
        state.isCategoryPickerPresented = true
        state.isPaymentMethodPickerPresented = true
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        state.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            category: "美妝",
            paymentMethod: "信用卡"
        )
        let store = TestStore(initialState: state) {
            OrderListFeature()
        }

        // When
        await store.send(.filterSheet(.presented(.view(.filterApplyTapped))))

        // Then
        await store.receive(
            \.filterSheet.presented.delegate.applied,
            OrderFilterSelection(datePeriod: .thisMonth, category: "美妝", paymentMethod: "信用卡")
        ) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedCategory = "美妝"
            $0.selectedPaymentMethod = "信用卡"
            $0.filterSheet = nil
        }
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedCategory == "美妝")
        #expect(store.state.selectedPaymentMethod == "信用卡")
        #expect(store.state.selectedStatus == .shipping)
        #expect(store.state.searchText == "林")
        #expect(store.state.isCategoryPickerPresented == true)
        #expect(store.state.isPaymentMethodPickerPresented == true)
        #expect(store.state.filterSheet == nil)
    }

    /// 面板開啟期間改已套用日期，未套用變更沿用目前清單的比較基準
    @Test
    func datePeriodSelected_篩選面板開啟中_同步子層已套用值() async {
        // Given
        var state = Self.makeState()
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.datePeriodSelected(.thisMonth))) {
            $0.selectedDatePeriod = .thisMonth
            $0.filterSheet?.committedFilterSelection.datePeriod = .thisMonth
        }

        // Then
        await store.receive(\.delegate.selectionChanged, nil)
        #expect(store.state.filterSheet?.committedFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.filterSheet?.pendingFilterSelection.datePeriod == .all)
        #expect(store.state.filterSheet?.hasUnappliedFilterChanges == true)
    }

    /// Root 的跨功能導覽直接更新清單時，仍同步面板比較基準並保留付款方式
    @Test
    func applyFilterNavigation_篩選面板開啟中_同步子層並保留付款方式() {
        // Given
        var state = Self.makeState()
        state.selectedStatus = .shipping
        state.selectedDatePeriod = .thisMonth
        state.selectedCategory = "美妝"
        state.selectedPaymentMethod = "信用卡"
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        state.filterSheet?.pendingFilterSelection = OrderFilterSelection()

        // When
        state.applyFilterNavigation(searchText: "林", category: nil)

        // Then
        #expect(state.selectedStatus == .all)
        #expect(state.searchText == "林")
        #expect(state.filterSheet?.committedFilterSelection.datePeriod == .all)
        #expect(state.filterSheet?.committedFilterSelection.category == nil)
        #expect(state.filterSheet?.committedFilterSelection.paymentMethod == "信用卡")
        #expect(state.filterSheet?.pendingFilterSelection.paymentMethod == nil)
        #expect(state.filterSheet?.hasUnappliedFilterChanges == true)
    }
}
