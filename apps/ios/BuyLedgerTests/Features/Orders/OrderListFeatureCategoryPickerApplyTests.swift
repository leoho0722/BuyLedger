//
//  OrderListFeatureCategoryPickerApplyTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 `TestStore` 逐步驗證類別選擇器的套用與取消結果
@MainActor
struct OrderListFeatureCategoryPickerApplyTests {

    /// 驗證類別選擇器加選 beauty 時只改暫存集合，背後清單仍依已套用的 snacks 篩選
    @Test
    func destination_類別選擇器加選美妝_不改背後清單篩選() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "beauty", category: "beauty"),
            OrdersFeatureTestSupport.makeOrder(id: "snacks", category: "snacks"),
        ])
        state.selectedCategories = ["snacks"]
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
        await store.send(
            .destination(.presented(.categoryPicker(.view(.categoryToggled("beauty")))))
        ) {
            $0.destination?.modify(\.categoryPicker) {
                $0.pendingCategories = ["snacks", "beauty"]
            }
        }

        // Then
        #expect(store.state.selectedCategories == ["snacks"])
        #expect(store.state.filteredOrders.map(\.id) == ["snacks"])
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["snacks", "beauty"])
    }

    /// 驗證提交 beauty 與 books 時，套用類別並關閉選擇器，清單只列出仍符合日期與付款方式的 A、B，不委派任何請求
    @Test
    func destination_完成兩項類別且日期付款並用_套用類別並關閉() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "cash", category: "beauty", paymentMethod: "現金"),
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "books", paymentMethod: "轉帳"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "beauty", paymentMethod: "轉帳"),
            OrdersFeatureTestSupport.makeOrder(id: "C", category: "snacks", paymentMethod: "轉帳"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedPaymentMethod = "轉帳"
        state.selectedCategories = ["snacks"]
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedPaymentMethod == "轉帳")
        #expect(store.state.filterSummary(language: .traditionalChinese) == "本月 · 2 項類別 · 轉帳")
    }

    /// 驗證類別全部取消後按完成，清單列出仍符合日期與付款方式的 A、B，不委派任何請求
    @Test
    func destination_類別全部取消後完成_保留日期與付款方式() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "books", paymentMethod: "信用卡"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "beauty", paymentMethod: "信用卡"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedPaymentMethod = "信用卡"
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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
            $0.destination = nil
        }
        #expect(store.state.filteredOrders.map(\.id) == ["A", "B"])
        #expect(store.state.selectedDatePeriod == .thisMonth)
        #expect(store.state.selectedPaymentMethod == "信用卡")
    }

    /// 驗證提交的集合與已套用值相同時，清單接收套用結果並關閉類別選擇器，已套用類別不變，不委派任何請求
    @Test
    func destination_完成時集合相同_只關閉選擇器且不委派() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "beauty"),
            OrdersFeatureTestSupport.makeOrder(id: "B", category: "beauty"),
        ])
        state.selectedCategories = ["beauty"]
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
        await store.send(.destination(.presented(.categoryPicker(.view(.doneTapped)))))

        // Then
        await store.receive(
            \.destination.presented.categoryPicker.delegate.applied,
            Set<String>(["beauty"])
        ) {
            $0.destination = nil
        }
        #expect(store.state.selectedCategories == ["beauty"])
    }

    /// 驗證確認捨棄後，選擇器把暫存還原為已套用的 beauty 並通知清單取消，清單的已套用類別不變
    @Test
    func destination_確認捨棄類別_保留已套用集合並關閉() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        picker.discardConfirmation = OrderCategoryPickerFeatureTestSupport.expectedDiscardAlert()
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

    /// 驗證選擇器未變更時按下取消，直接通知清單關閉，清單的已套用類別不變
    @Test
    func destination_未變更類別而取消_保留集合並關閉() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["beauty"]
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
        await store.send(.destination(.presented(.categoryPicker(.view(.cancelTapped)))))

        // Then
        await store.receive(\.destination.presented.categoryPicker.delegate.cancelled) {
            $0.destination = nil
        }
        #expect(store.state.selectedCategories == ["beauty"])
    }
}
