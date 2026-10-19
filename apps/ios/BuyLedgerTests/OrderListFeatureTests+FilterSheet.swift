//
//  OrderListFeatureTests+FilterSheet.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 關閉篩選面板後移除子層狀態
    @Test
    func destination_關閉篩選面板_清除子層狀態() async {
        // Given
        var state = OrdersFeature.State().list
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.destination == nil)
    }

    /// 下滑關閉沒有未套用變更的類別選擇器，移除唯一目的地
    @Test
    func destination_關閉類別選擇器_清除子層狀態() async {
        // Given
        var state = Self.makeState()
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.destination == nil)
    }

    /// 開啟篩選面板時，待確認篩選換成已套用的篩選，搜尋文字清空
    @Test
    func filterSheetTapped_開啟篩選面板_複製已提交篩選值() async {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = nil
        // 先放入過期的待確認值與搜尋文字，確認開啟時會被覆寫
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: ["stale"],
                paymentMethod: "stale"
            )
            $0.filterSheetSearchText = "leftover"
        }
        let expectedSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty"],
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterSheetTapped)) {
            $0.destination?.modify(\.filterSheet) {
                $0.pendingFilterSelection.datePeriod = .thisMonth
                $0.pendingFilterSelection.categories = ["beauty"]
                $0.pendingFilterSelection.paymentMethod = nil
                $0.filterSheetSearchText = ""
            }
        }

        // Then
        #expect(store.state.destination?.filterSheet?.pendingFilterSelection == expectedSelection)
        #expect(store.state.destination?.filterSheet?.filterSheetSearchText == "")
        #expect(store.state.destination != nil)
    }

    /// 套用變更過的篩選時提交新篩選，選取改為第一筆符合的訂單並關閉面板
    @Test
    func destination_待確認篩選已變更_提交並關閉面板() async {
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
        state.list.selectedCategories = []
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N1"
        state.list.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state.list))
        state.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: ["beauty"],
                paymentMethod: nil
            )
        }
        let store = TestStore(initialState: state.list) {
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
            OrderFilterSelection(datePeriod: .all, categories: ["beauty"], paymentMethod: nil)
        ) {
            $0.selectedCategories = ["beauty"]
            $0.selectedOrderID = "N2"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged)
        #expect(store.state.selectedCategories == ["beauty"])
        #expect(store.state.selectedOrderID == "N2")
        #expect(store.state.destination == nil)
    }

    /// 篩選沒有變更時套用只關閉面板，選取的訂單不重算
    @Test
    func destination_待確認篩選沒有變更_關閉面板且保留原值() async {
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
        state.list.selectedCategories = ["beauty"]
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N2"
        state.list.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state.list))
        let committedFilterSelection = state.list.committedFilterSelection
        state.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = committedFilterSelection
        }

        let store = TestStore(initialState: state.list) {
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
            OrderFilterSelection(datePeriod: .all, categories: ["beauty"], paymentMethod: nil)
        ) {
            $0.destination = nil
        }
        #expect(store.state.destination == nil)
        #expect(store.state.selectedCategories == ["beauty"])
        #expect(store.state.selectedOrderID == "N2")
    }

    /// 篩選有未套用的變更時取消，先詢問是否捨棄
    @Test
    func destination_待確認篩選有變更_呈現捨棄確認() async {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: [],
                paymentMethod: nil
            )
        }
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

        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterCancelTapped))))) {
            $0.destination?.modify(\.filterSheet) {
                $0.filterDiscardConfirmation = expectedConfirmation
            }
        }

        // Then
        #expect(
            store.state.destination?.filterSheet?.filterDiscardConfirmation == expectedConfirmation
        )
        #expect(store.state.destination != nil)
    }

    /// 確認捨棄後，待確認篩選還原成已套用的篩選並關閉面板
    @Test
    func destination_確認捨棄待確認篩選_還原並關閉面板() async {
        // Given
        var state = Self.makeState()
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "信用卡"
            )
        }
        let confirmation = OrdersFeatureTests.expectedDiscardAlert()
        state.destination?.modify(\.filterSheet) {
            $0.filterDiscardConfirmation = confirmation
        }

        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.filterSheet(.filterDiscardConfirmation(.presented(.discard)))))
        ) {
            $0.destination?.modify(\.filterSheet) {
                $0.filterDiscardConfirmation = nil
                $0.pendingFilterSelection.datePeriod = .all
                $0.pendingFilterSelection.categories = []
                $0.pendingFilterSelection.paymentMethod = nil
            }
        }

        // Then
        await store.receive(\.destination.presented.filterSheet.delegate.cancelled) {
            $0.destination = nil
        }
        #expect(store.state.destination == nil)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategories == [])
        #expect(store.state.selectedPaymentMethod == nil)
    }

    /// 篩選沒有變更時取消，不詢問直接關閉面板
    @Test
    func destination_待確認篩選沒有變更_直接關閉面板() async {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = nil
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        let committedFilterSelection = state.committedFilterSelection
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = committedFilterSelection
        }

        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterCancelTapped)))))

        // Then
        await store.receive(\.destination.presented.filterSheet.delegate.cancelled) {
            $0.destination = nil
        }
        #expect(store.state.destination == nil)
    }
}
