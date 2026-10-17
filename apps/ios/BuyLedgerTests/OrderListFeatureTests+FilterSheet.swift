//
//  OrderListFeatureTests+FilterSheet.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 關閉篩選面板後移除子層狀態
    @Test
    func filterSheet_關閉篩選面板_清除子層狀態() async {
        // Given
        var state = OrdersFeature.State().list
        state.filterSheet = OrderFilterFeatureTests.makeState(for: state)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        }

        // When
        await store.send(.filterSheet(.dismiss)) {
            $0.filterSheet = nil
        }

        // Then
        #expect(store.state.filterSheet == nil)
    }

    /// 切換類別或付款方式選擇器的顯示與否，對應的狀態跟著更新
    ///
    /// - Parameter picker: 要切換的選擇器
    @Test(arguments: OrdersFeatureTests.FilterPicker.allCases)
    func binding_切換選擇器_更新呈現狀態(picker: OrdersFeatureTests.FilterPicker) async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State().list) {
            OrderListFeature()
        }

        // When
        await store.send(.binding(.set(picker.keyPath, true))) {
            $0[keyPath: picker.keyPath] = true
        }

        // Then
        #expect(store.state[keyPath: picker.keyPath])
    }

    /// 開啟篩選面板時，待確認篩選換成已套用的篩選，搜尋文字清空
    @Test
    func filterSheetTapped_開啟篩選面板_複製已提交篩選值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .thisMonth
        state.list.selectedCategory = "beauty"
        state.list.selectedPaymentMethod = nil
        // 先放入過期的待確認值與搜尋文字，確認開啟時會被覆寫
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        state.list.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .all,
            category: "stale",
            paymentMethod: "stale"
        )
        state.list.filterSheet?.filterSheetSearchText = "leftover"
        let expectedSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            category: "beauty",
            paymentMethod: nil
        )

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        }

        // When
        await store.send(.view(.filterSheetTapped)) {
            $0.filterSheet?.pendingFilterSelection.datePeriod = .thisMonth
            $0.filterSheet?.pendingFilterSelection.category = "beauty"
            $0.filterSheet?.pendingFilterSelection.paymentMethod = nil
            $0.filterSheet?.filterSheetSearchText = ""
        }

        // Then
        #expect(store.state.filterSheet?.pendingFilterSelection == expectedSelection)
        #expect(store.state.filterSheet?.filterSheetSearchText == "")
        #expect(store.state.filterSheet != nil)
    }

    /// 套用變更過的篩選時提交新篩選，選取改為第一筆符合的訂單並關閉面板
    @Test
    func filterSheet_待確認篩選已變更_提交並關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        // 只有 N2 屬於 beauty，套用後選取改為 N2
        state.$orders.withLock {
            $0 = [
                OrdersFeatureTests.makeOrder(id: "N1", category: "electronics"),
                OrdersFeatureTests.makeOrder(id: "N2", category: "beauty"),
                OrdersFeatureTests.makeOrder(id: "N3", category: "electronics"),
            ]
        }
        state.list.selectedDatePeriod = .all
        state.list.selectedCategory = nil
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N1"
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        state.list.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .all,
            category: "beauty",
            paymentMethod: nil
        )
        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterSheet(.presented(.view(.filterApplyTapped))))

        // Then
        await store.receive(
            \.filterSheet.presented.delegate.applied,
            OrderFilterSelection(datePeriod: .all, category: "beauty", paymentMethod: nil)
        ) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "N2"
            $0.filterSheet = nil
        }
        await store.receive(\.delegate.selectionChanged)
        #expect(store.state.selectedCategory == "beauty")
        #expect(store.state.selectedOrderID == "N2")
        #expect(store.state.filterSheet == nil)
    }

    /// 篩選沒有變更時套用只關閉面板，選取的訂單不重算
    @Test
    func filterSheet_待確認篩選沒有變更_關閉面板且保留原值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        // 兩筆都命中篩選；選取 N2 用來確認不會重算
        state.$orders.withLock {
            $0 = [
                OrdersFeatureTests.makeOrder(id: "N1", category: "beauty"),
                OrdersFeatureTests.makeOrder(id: "N2", category: "beauty"),
            ]
        }
        state.list.selectedDatePeriod = .all
        state.list.selectedCategory = "beauty"
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N2"
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        let committedFilterSelection = state.list.committedFilterSelection
        state.list.filterSheet?.pendingFilterSelection = committedFilterSelection

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterSheet(.presented(.view(.filterApplyTapped))))

        // Then
        await store.receive(
            \.filterSheet.presented.delegate.applied,
            OrderFilterSelection(datePeriod: .all, category: "beauty", paymentMethod: nil)
        ) {
            $0.filterSheet = nil
        }
        #expect(store.state.filterSheet == nil)
        #expect(store.state.selectedCategory == "beauty")
        #expect(store.state.selectedOrderID == "N2")
    }

    /// 篩選有未套用的變更時取消，先詢問是否捨棄
    @Test
    func filterSheet_待確認篩選有變更_呈現捨棄確認() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .all
        state.list.selectedCategory = nil
        state.list.selectedPaymentMethod = nil
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        state.list.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            category: nil,
            paymentMethod: nil
        )
        let expectedConfirmation = AlertState<OrderFilterFeature.Action.FilterDiscardAlert> {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("orders.list.message.filtersHaveApplied")
        }

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        }

        // When
        await store.send(.filterSheet(.presented(.view(.filterCancelTapped)))) {
            $0.filterSheet?.filterDiscardConfirmation = expectedConfirmation
        }

        // Then
        #expect(store.state.filterSheet?.filterDiscardConfirmation == expectedConfirmation)
        #expect(store.state.filterSheet != nil)
    }

    /// 確認捨棄後，待確認篩選還原成已套用的篩選並關閉面板
    @Test
    func filterSheet_確認捨棄待確認篩選_還原並關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        state.list.filterSheet?.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            category: "beauty",
            paymentMethod: "信用卡"
        )
        let confirmation = OrdersFeatureTests.expectedDiscardAlert()
        state.list.filterSheet?.filterDiscardConfirmation = confirmation

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        }

        // When
        await store.send(
            .filterSheet(.presented(.filterDiscardConfirmation(.presented(.discard))))
        ) {
            $0.filterSheet?.filterDiscardConfirmation = nil
            $0.filterSheet?.pendingFilterSelection.datePeriod = .all
            $0.filterSheet?.pendingFilterSelection.category = nil
            $0.filterSheet?.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        await store.receive(\.filterSheet.presented.delegate.cancelled) {
            $0.filterSheet = nil
        }
        #expect(store.state.filterSheet == nil)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
    }

    /// 篩選沒有變更時取消，不詢問直接關閉面板
    @Test
    func filterSheet_待確認篩選沒有變更_直接關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .thisMonth
        state.list.selectedCategory = "beauty"
        state.list.selectedPaymentMethod = nil
        state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
        let committedFilterSelection = state.list.committedFilterSelection
        state.list.filterSheet?.pendingFilterSelection = committedFilterSelection

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        }

        // When
        await store.send(.filterSheet(.presented(.view(.filterCancelTapped))))

        // Then
        await store.receive(\.filterSheet.presented.delegate.cancelled) {
            $0.filterSheet = nil
        }
        #expect(store.state.filterSheet == nil)
    }
}
