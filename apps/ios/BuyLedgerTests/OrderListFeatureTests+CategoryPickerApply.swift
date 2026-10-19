//
//  OrderListFeatureTests+CategoryPickerApply.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 子層加選不提前套用，背後清單仍依原本 snacks 篩選
    @Test
    func destination_類別選擇器加選美妝_不改背後清單篩選與選取() async {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "beauty", category: "beauty"),
            OrdersFeatureTests.makeOrder(id: "snacks", category: "snacks"),
        ])
        state.selectedCategories = ["snacks"]
        state.selectedOrderID = "snacks"
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.categoryPicker(.view(.categoryToggled("beauty")))))
        ) {
            $0.destination?.modify(\.categoryPicker) {
                $0.pendingCategories = ["snacks", "beauty"]
            }
        }

        // Then
        #expect(store.state.selectedCategories == ["snacks"])
        #expect(store.state.selectedOrderID == "snacks")
        #expect(store.state.filteredOrders.map(\.id) == ["snacks"])
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["snacks", "beauty"])
    }

    /// 完成提交兩類，保留日期與付款條件，以最後篩選結果重選且只委派一次
    @Test
    func destination_完成兩項類別且日期付款並用_提交集合重選一次並關閉() async {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "cash", category: "beauty", paymentMethod: "現金"),
            OrdersFeatureTests.makeOrder(id: "A", category: "books", paymentMethod: "轉帳"),
            OrdersFeatureTests.makeOrder(id: "B", category: "beauty", paymentMethod: "轉帳"),
            OrdersFeatureTests.makeOrder(id: "C", category: "snacks", paymentMethod: "轉帳"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedPaymentMethod = "轉帳"
        state.selectedCategories = ["snacks"]
        state.selectedOrderID = "C"
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        state.destination = .categoryPicker(picker)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.view(.doneTapped)))))

        // Then
        await store.receive(
            \.destination.presented.categoryPicker.delegate.applied,
            Set<String>(["beauty", "books"])
        ) {
            $0.selectedCategories = ["beauty", "books"]
            $0.selectedOrderID = "A"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "A")
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedPaymentMethod == "轉帳")
        #expect(store.state.filterSummary(language: .traditionalChinese) == "本月 · 2 項類別 · 轉帳")
    }

    /// 全部後完成只清類別，還原符合其餘條件的訂單
    @Test
    func destination_全部後完成_清空類別且保留日期付款方式() async {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", category: "books", paymentMethod: "信用卡"),
            OrdersFeatureTests.makeOrder(id: "B", category: "beauty", paymentMethod: "信用卡"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedPaymentMethod = "信用卡"
        state.selectedCategories = ["beauty"]
        state.selectedOrderID = "B"
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = []
        state.destination = .categoryPicker(picker)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.view(.doneTapped)))))

        // Then
        await store.receive(
            \.destination.presented.categoryPicker.delegate.applied,
            Set<String>()
        ) {
            $0.selectedCategories = []
            $0.selectedOrderID = "A"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "A")
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedPaymentMethod == "信用卡")
    }

    /// 相同集合只關閉選擇器，不把使用者選取重設為第一筆
    @Test
    func destination_完成時集合相同_關閉且不重選或委派() async {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", category: "beauty"),
            OrdersFeatureTests.makeOrder(id: "B", category: "beauty"),
        ])
        state.selectedCategories = ["beauty"]
        state.selectedOrderID = "B"
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.view(.doneTapped)))))

        // Then
        await store.receive(
            \.destination.presented.categoryPicker.delegate.applied,
            Set<String>(["beauty"])
        ) {
            $0.destination = nil
        }
        #expect(store.state.selectedCategories == ["beauty"])
        #expect(store.state.selectedOrderID == "B")
    }

    /// 集合改變但首筆仍相同時提交且關閉，不發重複選取委派
    @Test
    func destination_類別變更但首筆相同_提交且不重複委派() async {
        // Given
        var state = Self.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "A", category: "beauty"),
            OrdersFeatureTests.makeOrder(id: "B", category: "books"),
        ])
        state.selectedCategories = ["beauty"]
        state.selectedOrderID = "A"
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        state.destination = .categoryPicker(picker)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.view(.doneTapped)))))

        // Then
        await store.receive(
            \.destination.presented.categoryPicker.delegate.applied,
            Set<String>(["beauty", "books"])
        ) {
            $0.selectedCategories = ["beauty", "books"]
            $0.destination = nil
        }
        #expect(store.state.selectedOrderID == "A")
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
    }

    /// 確認捨棄由子層還原暫存再請父層關閉，清單不提交
    @Test
    func destination_確認捨棄類別_保留已套用集合並關閉() async {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        picker.discardConfirmation = OrderCategoryPickerFeatureTests.expectedDiscardAlert()
        state.destination = .categoryPicker(picker)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.categoryPicker(.discardConfirmation(.presented(.discard)))))
        ) {
            $0.destination?.modify(\.categoryPicker) {
                $0.discardConfirmation = nil
                $0.pendingCategories = ["beauty"]
            }
        }

        // Then
        await store.receive(\.destination.presented.categoryPicker.delegate.cancelled) {
            $0.destination = nil
        }
        #expect(store.state.selectedCategories == ["beauty"])
    }

    /// 沒有修改時取消直接關閉，不改清單類別
    @Test
    func destination_未變更類別而取消_保留集合並關閉() async {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["beauty"]
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.categoryPicker(.view(.cancelTapped)))))

        // Then
        await store.receive(\.destination.presented.categoryPicker.delegate.cancelled) {
            $0.destination = nil
        }
        #expect(store.state.selectedCategories == ["beauty"])
    }
}
