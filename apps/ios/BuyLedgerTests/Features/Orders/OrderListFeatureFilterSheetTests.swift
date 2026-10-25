//
//  OrderListFeatureFilterSheetTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證篩選面板的開啟、套用、取消與捨棄確認
@MainActor
struct OrderListFeatureFilterSheetTests {

    /// 驗證關閉篩選面板時，清單的目的地清空，篩選面板的狀態一併移除
    @Test
    func destination_關閉篩選面板_清除子層狀態() async {
        // Given
        var state = OrdersFeature.State().list
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證沒有未套用變更的類別選擇器被下滑關閉時，清單的目的地清空
    @Test
    func destination_關閉類別選擇器_清除子層狀態() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        )
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

    /// 驗證開啟篩選面板時，殘留的暫存篩選換成已套用的日期與類別，搜尋文字清空
    @Test
    func filterSheetTapped_開啟篩選面板_複製已提交篩選值() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = nil
        // 預先放入過期的暫存值與搜尋文字，開啟時應被覆寫
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證篩選面板的暫存有變更時按下套用，類別改為 beauty 並關閉面板，選取從 N1 改為符合的第一筆 N2
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
                OrdersFeatureTestSupport.makeOrder(id: "N1", category: "electronics"),
                OrdersFeatureTestSupport.makeOrder(id: "N2", category: "beauty"),
                OrdersFeatureTestSupport.makeOrder(id: "N3", category: "electronics"),
            ]
        }
        state.list.selectedDatePeriod = .all
        state.list.selectedCategories = []
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N1"
        state.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: state.list)
        )
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

    /// 驗證提交的集合與已套用值相同時，清單接收套用結果並關閉篩選面板，保留選取的訂單 N2，不再回報選取變更
    @Test
    func destination_待確認篩選沒有變更_關閉面板且保留原值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        // 兩筆都命中篩選，選取 N2 用來確認套用時不重算
        state.$orders.withLock {
            $0 = [
                OrdersFeatureTestSupport.makeOrder(id: "N1", category: "beauty"),
                OrdersFeatureTestSupport.makeOrder(id: "N2", category: "beauty"),
            ]
        }
        state.list.selectedDatePeriod = .all
        state.list.selectedCategories = ["beauty"]
        state.list.selectedPaymentMethod = nil
        state.list.selectedOrderID = "N2"
        state.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: state.list)
        )
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

    /// 驗證篩選面板有未套用變更時按下取消，不關閉面板，改呈現捨棄確認框
    @Test
    func destination_待確認篩選有變更_呈現捨棄確認() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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

    /// 驗證確認捨棄後，暫存篩選還原為清單已套用的日期、類別與付款方式，並通知清單取消關閉面板
    @Test
    func destination_確認捨棄待確認篩選_還原並關閉面板() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty"],
                paymentMethod: "信用卡"
            )
        }
        let confirmation = OrdersFeatureTestSupport.expectedDiscardAlert()
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

    /// 驗證篩選面板沒有未套用變更時按下取消，不呈現捨棄確認，直接通知清單關閉面板
    @Test
    func destination_待確認篩選沒有變更_直接關閉面板() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = nil
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
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
