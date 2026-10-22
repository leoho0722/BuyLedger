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

/// 整合篩選的暫存、套用與捨棄確認
@MainActor
struct OrderFilterFeatureTests {

    /// 調整日期只改暫存值
    @Test
    func filterPendingDatePeriodSelected_選擇本月_保留已套用日期() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
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

    /// 調整類別只改暫存值
    @Test
    func filterPendingCategoryToggled_選擇美妝_保留已套用類別() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
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

    /// 調整付款方式只改暫存值
    @Test
    func filterPendingPaymentMethodSelected_選擇信用卡_保留已套用付款方式() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
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

    /// 套用時把三欄選擇交給清單，不自行修改已套用值
    @Test
    func filterApplyTapped_暫存三欄已變更_委派完整選擇() async {
        // Given
        var state = Self.makeState()
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

    /// 未修改時取消直接通知清單關閉
    @Test
    func filterCancelTapped_沒有未套用變更_委派取消() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
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

    /// 有變更時保留暫存並呈現原有捨棄確認文字
    @Test
    func filterCancelTapped_仍有暫存變更_呈現捨棄確認() async {
        // Given
        var state = Self.makeState()
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

    /// 捨棄時還原三欄並委派取消，不提交暫存
    @Test
    func filterDiscardConfirmation_確認捨棄_還原暫存並委派取消() async {
        // Given
        var state = Self.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["美妝", "書籍"],
            paymentMethod: "信用卡"
        )
        state.filterDiscardConfirmation = OrdersFeatureTests.expectedDiscardAlert()
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

    /// 關閉捨棄確認後可以繼續編輯暫存，不委派取消
    @Test
    func filterDiscardConfirmation_繼續編輯_保留暫存選擇() async {
        // Given
        var state = Self.makeState()
        state.pendingFilterSelection.categories = ["美妝"]
        state.filterDiscardConfirmation = OrdersFeatureTests.expectedDiscardAlert()
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

    /// 已套用值不是預設時，捨棄還原目前三欄並通知清單關閉
    @Test
    func filterDiscardConfirmation_已套用三欄非預設_還原目前選擇() async {
        // Given
        var state = Self.makeState()
        state.committedFilterSelection = OrderFilterSelection(
            datePeriod: .thisWeek,
            categories: ["美妝"],
            paymentMethod: "現金"
        )
        state.pendingFilterSelection = OrderFilterSelection()
        state.filterDiscardConfirmation = OrdersFeatureTests.expectedDiscardAlert()
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

// MARK: - Internal Method

extension OrderFilterFeatureTests {

    /// 建立沒有訂單、可指定類別與已套用篩選的子層狀態
    ///
    /// - Parameters:
    ///   - categories: 可用的主檔類別，預設為空
    ///   - committedFilterSelection: 已套用篩選，預設為全部
    /// - Returns: 不存取持久化主檔的測試初始值
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static func makeState(
        categories: [String] = [],
        committedFilterSelection: OrderFilterSelection = OrderFilterSelection()
    ) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: categories)),
            committedFilterSelection: committedFilterSelection,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 使用清單的共用引用建立篩選子層，供呈現與提交測試直接設定初始狀態
    ///
    /// - Parameter state: 清單的共用資料與已套用篩選
    /// - Returns: 暫存值與已套用值一致的篩選狀態
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static func makeState(
        for state: OrderListFeature.State
    ) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: state.$orders,
            campaigns: state.$campaigns,
            lookupCatalog: state.$lookupCatalog,
            committedFilterSelection: state.committedFilterSelection,
            dateContext: state.dateContext ?? OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }
}
