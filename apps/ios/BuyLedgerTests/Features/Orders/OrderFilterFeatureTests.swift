//
//  OrderFilterFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderFilterFeature` 的單元測試，以 TestStore 逐步驗證暫存選擇、套用、取消與捨棄確認
@MainActor
struct OrderFilterFeatureTests {

    /// 驗證選擇本月日期時只改暫存的日期期間，已套用的日期期間維持全部
    @Test
    func filterPendingDatePeriodSelected_選擇本月_保留已套用日期() async {
        // Given
        let store = TestStore(initialState: OrderFilterFeatureTestSupport.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingDatePeriodSelected(.thisMonth))) {
            $0.pendingFilterSelection.datePeriod = .thisMonth
        }

        // Then
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
    }

    /// 驗證勾選美妝類別時只改暫存類別，已套用的類別仍為空
    @Test
    func filterPendingCategoryToggled_選擇美妝_保留已套用類別() async {
        // Given
        let store = TestStore(initialState: OrderFilterFeatureTestSupport.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled("美妝"))) {
            $0.pendingFilterSelection.categories = ["美妝"]
        }

        // Then
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.pendingFilterSelection.categories == ["美妝"])
    }

    /// 驗證選擇信用卡付款方式時只改暫存值，已套用的付款方式仍未設定
    @Test
    func filterPendingPaymentMethodSelected_選擇信用卡_保留已套用付款方式() async {
        // Given
        let store = TestStore(initialState: OrderFilterFeatureTestSupport.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingPaymentMethodSelected("信用卡"))) {
            $0.pendingFilterSelection.paymentMethod = "信用卡"
        }

        // Then
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
        #expect(store.state.pendingFilterSelection.paymentMethod == "信用卡")
    }

    /// 驗證按下套用時，篩選面板把暫存的三欄選擇原樣通知清單，自身的已套用值不變
    @Test
    func filterApplyTapped_暫存三欄已變更_委派完整選擇() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["美妝"],
            paymentMethod: "信用卡"
        )
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterApplyTapped))

        // Then
        await store.receive(
            \.delegate.applied,
            OrderFilterSelection(datePeriod: .thisMonth, categories: ["美妝"], paymentMethod: "信用卡")
        )
        #expect(store.state.committedFilterSelection.datePeriod == .all)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.committedFilterSelection.paymentMethod == nil)
    }

    /// 驗證沒有未套用變更時按下取消，直接通知清單關閉，不出現捨棄確認
    @Test
    func filterCancelTapped_沒有未套用變更_委派取消() async {
        // Given
        let store = TestStore(initialState: OrderFilterFeatureTestSupport.makeState()) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterCancelTapped))

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.filterDiscardConfirmation == nil)
    }

    /// 驗證仍有暫存變更時按下取消，不通知清單關閉，改呈現捨棄確認框並保留暫存選擇
    @Test
    func filterCancelTapped_仍有暫存變更_呈現捨棄確認() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection.categories = ["美妝", "書籍"]
        let confirmation = AlertState<OrderFilterFeature.Action.FilterDiscardAlert> {
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
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterCancelTapped)) {
            $0.filterDiscardConfirmation = confirmation
        }

        // Then
        #expect(store.state.pendingFilterSelection.categories == ["美妝", "書籍"])
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.filterDiscardConfirmation == confirmation)
    }

    /// 驗證確認捨棄時，暫存三欄還原為預設值並通知清單取消，不會把暫存套用出去
    @Test
    func filterDiscardConfirmation_確認捨棄_還原暫存並委派取消() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["美妝", "書籍"],
            paymentMethod: "信用卡"
        )
        state.filterDiscardConfirmation = OrdersFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterDiscardConfirmation(.presented(.discard))) {
            $0.filterDiscardConfirmation = nil
            $0.pendingFilterSelection.datePeriod = .all
            $0.pendingFilterSelection.categories = []
            $0.pendingFilterSelection.paymentMethod = nil
        }

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.pendingFilterSelection.datePeriod == .all)
        #expect(store.state.pendingFilterSelection.categories == [])
        #expect(store.state.pendingFilterSelection.paymentMethod == nil)
    }

    /// 驗證關閉捨棄確認後，確認框消失且暫存的類別保留，不通知清單取消
    @Test
    func filterDiscardConfirmation_繼續編輯_保留暫存選擇() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.pendingFilterSelection.categories = ["美妝"]
        state.filterDiscardConfirmation = OrdersFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterDiscardConfirmation(.dismiss)) {
            $0.filterDiscardConfirmation = nil
        }

        // Then
        #expect(store.state.pendingFilterSelection.categories == ["美妝"])
        #expect(store.state.committedFilterSelection.categories == [])
    }

    /// 驗證已套用的三欄不是預設值時，確認捨棄會把暫存還原為已套用的三欄，並通知清單取消
    @Test
    func filterDiscardConfirmation_已套用三欄非預設_還原目前選擇() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
        state.committedFilterSelection = OrderFilterSelection(
            datePeriod: .thisWeek,
            categories: ["美妝"],
            paymentMethod: "現金"
        )
        state.pendingFilterSelection = OrderFilterSelection()
        state.filterDiscardConfirmation = OrdersFeatureTestSupport.expectedDiscardAlert()
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterDiscardConfirmation(.presented(.discard))) {
            $0.filterDiscardConfirmation = nil
            $0.pendingFilterSelection.datePeriod = .thisWeek
            $0.pendingFilterSelection.categories = ["美妝"]
            $0.pendingFilterSelection.paymentMethod = "現金"
        }

        // Then
        await store.receive(\.delegate.cancelled)
        #expect(store.state.pendingFilterSelection.datePeriod == .thisWeek)
        #expect(store.state.pendingFilterSelection.categories == ["美妝"])
        #expect(store.state.pendingFilterSelection.paymentMethod == "現金")
    }
}
