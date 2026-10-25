//
//  OrdersFilterOperationsFilterSheetTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFilterOperations` 的單元測試，直接呼叫篩選面板的互動方法，斷言暫存篩選與已套用篩選的變化
struct OrdersFilterOperationsFilterSheetTests {

    /// 驗證點選類別時，類別選擇器的待選與已提交類別都是已套用的類別，搜尋文字為空，且不開啟篩選面板
    @Test
    func categoryPickerTapped_點選類別_顯示選擇器() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["美妝"]
        state.searchText = "殘留文字"
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

    /// 驗證開啟面板時，待選篩選複製自目前已套用的篩選，殘留的搜尋文字清空
    @Test
    func filterSheetTapped_開啟面板_複製篩選並清空搜尋() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .thisWeek
        state.selectedCategories = ["美妝"]
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證選取日期 `thisMonth` 時，只寫入待選篩選，已套用篩選的日期仍為 `all`
    @Test
    func filterPendingDatePeriodSelected_選取日期_暫存日期且不改已套用篩選() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()

        // When
        OrdersFilterOperations.filterPendingDatePeriodSelected(.thisMonth, state: &state)

        // Then
        #expect(state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(state.committedFilterSelection.datePeriod == .all)
    }

    /// 驗證選取付款方式「信用卡」時，只寫入待選篩選，已套用篩選的付款方式仍為 `nil`
    @Test
    func filterPendingPaymentMethodSelected_選取付款方式_暫存付款方式且不改已套用篩選() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()

        // When
        OrdersFilterOperations.filterPendingPaymentMethodSelected("信用卡", state: &state)

        // Then
        #expect(state.pendingFilterSelection.paymentMethod == "信用卡")
        #expect(state.committedFilterSelection.paymentMethod == nil)
    }

    /// 驗證篩選改為類別「服飾」套用時，已套用類別更新、選取重選為符合條件的第一筆 B，並關閉篩選面板
    @Test
    func filterApplied_變更類別_套用並重選第一筆() {
        // Given
        let initialOrders = [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", category: "美妝"),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B", category: "服飾"),
        ]
        var state = OrderListFeatureTestSupport.makeState(orders: initialOrders)
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))

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

    /// 驗證套用的篩選與目前相同時，選取的 A 不變，篩選面板直接關閉
    @Test
    func filterApplied_沒有變更_關閉面板並保留選取() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", category: "美妝"),
        ])
        state.selectedOrderID = "A"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))

        // When
        OrdersFilterOperations.filterApplied(
            OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil),
            state: &state
        )

        // Then
        #expect(state.selectedOrderID == "A")
        #expect(state.destination == nil)
    }

    /// 驗證待選篩選與已套用相同時按下取消，回傳 `cancelled`，不呈現捨棄確認
    @Test
    func filterCancelTapped_沒有變更_直接關閉面板() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()

        // When
        let delegate = OrdersFilterOperations.filterCancelTapped(state: &state)

        // Then
        #expect(delegate == .cancelled)
        #expect(state.filterDiscardConfirmation == nil)
    }

    /// 驗證待選篩選與已套用不同時按下取消，不回傳 `cancelled`，改為呈現捨棄確認
    @Test
    func filterCancelTapped_尚有變更_呈現捨棄確認() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection.categories = ["美妝"]

        // When
        let delegate = OrdersFilterOperations.filterCancelTapped(state: &state)

        // Then
        #expect(delegate == nil)
        #expect(state.filterDiscardConfirmation != nil)
    }

    /// 驗證確認捨棄時，待選篩選還原為全部日期、無類別、無付款方式的預設篩選
    @Test
    func filterDiscardConfirmed_確認捨棄_還原暫存() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
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
