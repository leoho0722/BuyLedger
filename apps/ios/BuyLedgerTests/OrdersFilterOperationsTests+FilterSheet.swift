//
//  OrdersFilterOperationsTests+FilterSheet.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrdersFilterOperationsTests {

    /// 驗證點選類別時顯示選擇器
    @Test
    func categoryPickerTapped_點選類別_顯示選擇器() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedCategories = ["美妝"]
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        OrdersFilterOperations.categoryPickerTapped(
            campaigns: state.$campaigns,
            context: context,
            state: &state
        )

        // Then
        #expect(state.destination?.categoryPicker?.pendingCategories == ["美妝"])
        #expect(state.destination?.categoryPicker?.committedCategories == ["美妝"])
        #expect(state.destination?.categoryPicker?.searchText == "")
        #expect(state.destination?.categoryPicker?.dateContext == context)
        #expect(state.destination?.filterSheet == nil)
    }

    /// 驗證開啟面板時複製篩選並清空搜尋
    @Test
    func filterSheetTapped_開啟面板_複製篩選並清空搜尋() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedDatePeriod = .thisWeek
        state.selectedCategories = ["美妝"]
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.filterSheetSearchText = "殘留文字"
        }
        let expectedSelection = OrderFilterSelection(
            datePeriod: .thisWeek,
            categories: ["美妝"],
            paymentMethod: nil
        )

        // When
        OrdersFilterOperations.filterSheetTapped(
            campaigns: state.$campaigns,
            context: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            ),
            state: &state
        )

        // Then
        #expect(state.destination?.filterSheet?.pendingFilterSelection == expectedSelection)
        #expect(state.destination?.filterSheet?.pendingFilterSelection.datePeriod == .thisWeek)
        #expect(state.destination?.filterSheet?.pendingFilterSelection.categories == ["美妝"])
        #expect(state.destination?.filterSheet?.filterSheetSearchText == "")
        #expect(state.destination != nil)
    }

    /// 驗證選取日期時只暫存日期，不改已套用篩選
    @Test
    func filterPendingDatePeriodSelected_選取日期_暫存日期且不改已套用篩選() {
        // Given
        var state = OrderFilterFeatureTests.makeState()

        // When
        OrdersFilterOperations.filterPendingDatePeriodSelected(.thisMonth, state: &state)

        // Then
        #expect(state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(state.committedFilterSelection.datePeriod == .all)
    }

    /// 驗證選取付款方式時只暫存付款方式，不改已套用篩選
    @Test
    func filterPendingPaymentMethodSelected_選取付款方式_暫存付款方式且不改已套用篩選() {
        // Given
        var state = OrderFilterFeatureTests.makeState()

        // When
        OrdersFilterOperations.filterPendingPaymentMethodSelected("信用卡", state: &state)

        // Then
        #expect(state.pendingFilterSelection.paymentMethod == "信用卡")
        #expect(state.committedFilterSelection.paymentMethod == nil)
    }

    /// 驗證變更類別時套用並重選第一筆
    @Test
    func filterApplied_變更類別_套用並重選第一筆() {
        // Given
        let initialOrders = [makeOrder(id: "A", category: "美妝"), makeOrder(id: "B", category: "服飾")]
        var state = OrderListFeatureTests.makeState(orders: initialOrders)
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))

        // When
        OrdersFilterOperations.filterApplied(
            OrderFilterSelection(datePeriod: .all, categories: ["服飾"], paymentMethod: nil),
            state: &state
        )

        // Then
        #expect(state.selectedCategories == ["服飾"])
        #expect(state.selectedOrderID == "B")
        #expect(state.destination == nil)
    }

    /// 驗證沒有變更時關閉面板並保留選取
    @Test
    func filterApplied_沒有變更_關閉面板並保留選取() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [makeOrder(id: "A", category: "美妝")])
        state.selectedOrderID = "A"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))

        // When
        OrdersFilterOperations.filterApplied(
            OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil),
            state: &state
        )

        // Then
        #expect(state.selectedOrderID == "A")
        #expect(state.destination == nil)
    }

    /// 驗證沒有變更時直接關閉面板
    @Test
    func filterCancelTapped_沒有變更_直接關閉面板() {
        // Given
        var state = OrderFilterFeatureTests.makeState()

        // When
        let delegate = OrdersFilterOperations.filterCancelTapped(state: &state)

        // Then
        #expect(delegate == .cancelled)
        #expect(state.filterDiscardConfirmation == nil)
    }

    /// 驗證尚有變更時呈現捨棄確認
    @Test
    func filterCancelTapped_尚有變更_呈現捨棄確認() {
        // Given
        var state = OrderFilterFeatureTests.makeState()
        state.pendingFilterSelection.categories = ["美妝"]

        // When
        let delegate = OrdersFilterOperations.filterCancelTapped(state: &state)

        // Then
        #expect(delegate == nil)
        #expect(state.filterDiscardConfirmation != nil)
    }

    /// 驗證確認捨棄時還原暫存
    @Test
    func filterDiscardConfirmed_確認捨棄_還原暫存() {
        // Given
        var state = OrderFilterFeatureTests.makeState()
        state.pendingFilterSelection.categories = ["美妝"]

        // When
        OrdersFilterOperations.filterDiscardConfirmed(state: &state)

        // Then
        #expect(
            state.pendingFilterSelection
                == OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        )
    }
}
