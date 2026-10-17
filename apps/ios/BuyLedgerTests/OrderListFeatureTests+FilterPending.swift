//
//  OrderListFeatureTests+FilterPending.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 調整待確認日期篩選只改暫存值，已套用的篩選不變
    @Test
    func filterSheet_調整待確認日期_不改已提交值() async {
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
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .filterSheet(.presented(.view(.filterPendingDatePeriodSelected(.thisMonth))))
        ) {
            $0.filterSheet?.pendingFilterSelection.datePeriod = .thisMonth
        }

        // Then
        #expect(store.state.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.filterSheet?.pendingFilterSelection.datePeriod == .thisMonth)
    }

    /// 調整待確認類別只改暫存值，已套用的篩選不變
    @Test
    func filterSheet_調整待確認類別_不改已提交值() async {
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
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .filterSheet(.presented(.view(.filterPendingCategorySelected("beauty"))))
        ) {
            $0.filterSheet?.pendingFilterSelection.category = "beauty"
        }

        // Then
        #expect(store.state.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.filterSheet?.pendingFilterSelection.category == "beauty")
    }

    /// 調整待確認付款方式只改暫存值，已套用的篩選不變
    @Test
    func filterSheet_調整待確認付款方式_不改已提交值() async {
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
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .filterSheet(.presented(.view(.filterPendingPaymentMethodSelected("信用卡"))))
        ) {
            $0.filterSheet?.pendingFilterSelection.paymentMethod = "信用卡"
        }

        // Then
        #expect(store.state.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.filterSheet?.pendingFilterSelection.paymentMethod == "信用卡")
    }

    /// 篩選面板輸入搜尋文字後，類別與付款方式只留下包含搜尋字串的項目，不分大小寫
    ///
    /// - Parameters:
    ///   - searchText: 要比對的搜尋文字
    ///   - expectedCategories: 預期留下的類別
    ///   - expectedPaymentMethods: 預期留下的付款方式
    /// - Note: 以唯讀常數目錄準備分類與付款方式，清單與篩選共用同一份引用
    @Test(arguments: [
        ("boo", ["books"], [String]()),
        ("ook", ["books"], [String]()),
        ("BOO", ["books"], [String]()),
        ("轉帳", [String](), ["轉帳"]),
    ])
    func filterSheet_輸入篩選搜尋文字_過濾分類與付款方式(
        searchText: String,
        expectedCategories: [String],
        expectedPaymentMethods: [String]
    ) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.$lookupCatalog = SharedReader(
                value: LookupCatalog(
                    categories: ["beauty", "snacks", "books"],
                    paymentMethods: [
                        PaymentMethodInfo(
                            name: "轉帳",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "orders.list.label.cashDelivery",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                    ]
                )
            )
            state.list.$lookupCatalog = state.$lookupCatalog

            state.list.filterSheet = OrderFilterFeatureTests.makeState(for: state.list)
            let store = TestStore(initialState: state.list) {
                OrderListFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(
                .filterSheet(.presented(.binding(.set(\.filterSheetSearchText, searchText))))
            ) {
                $0.filterSheet?.filterSheetSearchText = searchText
            }

            // Then
            #expect(store.state.filterSheet?.filterSheetFilteredCategories == expectedCategories)
            #expect(
                store.state.filterSheet?.filterSheetFilteredPaymentMethods == expectedPaymentMethods
            )
        }
    }
}
