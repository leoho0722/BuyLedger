//
//  OrdersFilterOperationsTests+FilterSheet.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrdersFilterOperationsTests {

    /// 驗證點選類別時顯示選擇器
    @Test
    func categoryPickerTapped_點選類別_顯示選擇器() {
        // Given
        var state = OrderListFeatureTests.makeState()

        // When
        OrdersFilterOperations.categoryPickerTapped(state: &state)

        // Then
        #expect(state.isCategoryPickerPresented == true)
    }

    /// 驗證點選付款方式時顯示選擇器
    @Test
    func paymentMethodPickerTapped_點選付款方式_顯示選擇器() {
        // Given
        var state = OrderListFeatureTests.makeState()

        // When
        OrdersFilterOperations.paymentMethodPickerTapped(state: &state)

        // Then
        #expect(state.isPaymentMethodPickerPresented == true)
    }

    /// 驗證開啟面板時複製篩選並清空搜尋
    @Test
    func filterSheetTapped_開啟面板_複製篩選並清空搜尋() {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.selectedDatePeriod = .thisWeek
        state.selectedCategory = "美妝"
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        state.filterSheet?.filterSheetSearchText = "殘留文字"
        let expectedSelection = OrderFilterSelection(
            datePeriod: .thisWeek,
            category: "美妝",
            paymentMethod: nil
        )

        // When
        OrdersFilterOperations.filterSheetTapped(state: &state)

        // Then
        #expect(state.filterSheet?.pendingFilterSelection == expectedSelection)
        #expect(state.filterSheet?.pendingFilterSelection.datePeriod == .thisWeek)
        #expect(state.filterSheet?.pendingFilterSelection.category == "美妝")
        #expect(state.filterSheet?.filterSheetSearchText == "")
        #expect(state.filterSheet != nil)
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

    /// 驗證選取類別時只暫存類別，不改已套用篩選
    @Test
    func filterPendingCategorySelected_選取類別_暫存類別且不改已套用篩選() {
        // Given
        var state = OrderFilterFeatureTests.makeState()

        // When
        OrdersFilterOperations.filterPendingCategorySelected("美妝", state: &state)

        // Then
        #expect(state.pendingFilterSelection.category == "美妝")
        #expect(state.committedFilterSelection.category == nil)
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
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)

        // When
        OrdersFilterOperations.filterApplied(
            OrderFilterSelection(datePeriod: .all, category: "服飾", paymentMethod: nil),
            state: &state
        )

        // Then
        #expect(state.selectedCategory == "服飾")
        #expect(state.selectedOrderID == "B")
        #expect(state.filterSheet == nil)
    }

    /// 驗證沒有變更時關閉面板並保留選取
    @Test
    func filterApplied_沒有變更_關閉面板並保留選取() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [makeOrder(id: "A", category: "美妝")])
        state.selectedOrderID = "A"
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)

        // When
        OrdersFilterOperations.filterApplied(
            OrderFilterSelection(datePeriod: .all, category: nil, paymentMethod: nil),
            state: &state
        )

        // Then
        #expect(state.selectedOrderID == "A")
        #expect(state.filterSheet == nil)
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
        state.pendingFilterSelection.category = "美妝"

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
        state.pendingFilterSelection.category = "美妝"

        // When
        OrdersFilterOperations.filterDiscardConfirmed(state: &state)

        // Then
        #expect(state.pendingFilterSelection == OrderFilterSelection())
    }
}
